import AuthenticationServices
import CoreLocation
import GoogleSignIn
import MapKit
import SwiftData
import SwiftUI

/// Full-screen form for manually creating a new event.
/// Pushed onto the NavigationStack from CreateEntryView.
///
/// Publish flow:
///   1. Tap "Publish" → runs validation
///   2. If invalid, surfaces all errors inline and stays open
///   3. If valid, inserts Event into ModelContext, fires onPublished callback,
///      then pops back via dismiss() — SwiftData's @Query in DiscoverView
///      updates reactively without any manual refresh
///
/// Cancel flow:
///   - Clean form → dismisses immediately
///   - Dirty form → confirmationDialog asking to discard or keep editing
struct CreateEventFormView: View {
    let onPublished: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var viewModel: CreateEventViewModel

    init(prefill: ExtractedEvent? = nil, onPublished: @escaping (String) -> Void) {
        self.onPublished = onPublished
        _viewModel = State(initialValue: CreateEventViewModel(prefill: prefill))
    }

    init(editing event: Event, onSaved: @escaping (String) -> Void) {
        self.onPublished = onSaved
        _viewModel = State(initialValue: CreateEventViewModel(editing: event))
    }
    @State private var showDiscard        = false
    @State private var cameraPosition     = MapCameraPosition.automatic
    @State private var geocodeTask: Task<Void, Never>?
    @State private var authCalloutDismissed = false
    /// True after the user taps the map to manually place the pin.
    /// Suppresses geocoder from overwriting their explicit choice until
    /// they edit the address field again.
    @State private var userManuallyPinned = false

    // MARK: - Body

    var body: some View {
        Form {
            authSection
            detailsSection
            categorySection
            dateSection
            recurrenceSection
            locationSection
            pricingSection
            organizerSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(viewModel.isEditMode ? "Edit Event" : "New Event")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading)  { cancelButton  }
            ToolbarItem(placement: .topBarTrailing) { publishButton }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
            }
        }
        .confirmationDialog(
            viewModel.isEditMode ? "Discard Changes?" : "Discard Event?",
            isPresented: $showDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            // No role — a roleless button maps to UIAlertAction(style: .default),
            // which is always rendered as a visible button in the action sheet.
            // role: .cancel maps to the sheet's dismiss-by-tapping-outside action
            // and is NOT rendered as a visible button when inside a NavigationStack.
            Button("Keep Editing") {}
        } message: {
            Text(viewModel.isEditMode ? "Your changes will be lost." : "You'll lose everything you've entered.")
        }
        .onAppear { centreMapOnDefault() }
        .onDisappear { geocodeTask?.cancel() }
    }

    // MARK: - Toolbar buttons

    private var cancelButton: some View {
        Button("Cancel") {
            if viewModel.isDirty { showDiscard = true } else { dismiss() }
        }
    }

    private var publishButton: some View {
        Button(viewModel.isEditMode ? "Save Changes" : "Publish") {
            print("🔔 Publish tapped: isValid=\(viewModel.isValid) isEditMode=\(viewModel.isEditMode)")
            viewModel.publishAttempted = true
            guard viewModel.isValid else { print("🔔 ❌ isValid=false, returning early"); return }
            if viewModel.isEditMode {
                viewModel.saveChanges()
                onPublished(viewModel.title.trimmingCharacters(in: .whitespaces))
            } else {
                let event = viewModel.buildEvent()
                modelContext.insert(event)
                print("🔔 calling scheduleCategoryNotification after publish")
                NotificationService.shared.scheduleCategoryNotification(
                    for: event,
                    userLocation: LocationService.shared.userLocation
                )
                onPublished(event.title)
            }
            dismiss()
        }
        .fontWeight(.semibold)
        .foregroundStyle(viewModel.isValid ? Color.accentColor : Color.secondary)
    }

    // MARK: - Form sections

    @ViewBuilder
    private var authSection: some View {
        if let identity = AuthService.shared.currentIdentity {
            Section {
                Label {
                    Text("Publishing as **\(identity.displayName ?? "Verified organizer")**")
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                }
            }
        } else if !authCalloutDismissed {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Post as a verified organizer")
                        .font(.headline)
                    Text("Sign in to edit or remove this event later. Posts without sign-in are community posts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SignInWithGoogleView(
                        onSuccess: { _ in },
                        onError: { _ in }
                    )
                    // Sign in with Apple requires a paid Apple Developer Program account ($99/yr).
                    // Re-enable this block once the paid account is active. See KNOWN_ISSUES.md.
                    #if false
                    SignInWithAppleView(
                        onSuccess: { _ in },
                        onError: { _ in }
                    )
                    #endif
                    Button("Skip for now") {
                        authCalloutDismissed = true
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        Section {
            // Title row: text field + live character count
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    TextField("Event title", text: $viewModel.title)
                        .onChange(of: viewModel.title) { _, _ in
                            viewModel.touchedFields.insert(.title)
                            viewModel.touchedConfidenceFields.insert("title")
                        }
                    Text("\(viewModel.title.count)/80")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(viewModel.title.count > 80 ? Color.red : Color.secondary)
                }
                .confidence(viewModel.confidenceLevel(for: "title"))
                if let err = viewModel.visibleError(for: .title) {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }

            // Description row: multi-line editor + char counter
            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: $viewModel.eventDescription)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 120)
                    .onChange(of: viewModel.eventDescription) { _, _ in
                        viewModel.touchedFields.insert(.description)
                    }
                HStack(alignment: .firstTextBaseline) {
                    if let err = viewModel.visibleError(for: .description) {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                    Spacer()
                    Text("\(viewModel.eventDescription.count)/500")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(viewModel.eventDescription.count > 500 ? Color.red : Color.secondary)
                }
            }
        } header: {
            Label("Event Details", systemImage: "text.bubble")
        }
    }

    @ViewBuilder
    private var categorySection: some View {
        Section {
            // Explicit Binding avoids a navigation-Picker pop-back quirk where
            // $viewModel.category's dynamic-member-lookup setter isn't reliably
            // called for enum types on @Observable classes held in @State.
            Picker("Category", selection: Binding(
                get: { viewModel.category },
                set: { viewModel.category = $0 }
            )) {
                ForEach(EventCategory.allCases, id: \.self) { cat in
                    Label(cat.displayName, systemImage: cat.systemImage).tag(cat)
                }
            }
        } header: {
            Label("Category", systemImage: "tag")
        }
    }

    @ViewBuilder
    private var dateSection: some View {
        Section {
            if viewModel.prefillDateIsPast {
                Label(
                    "This poster's date is in the past. Update the date before publishing, or the poster may be outdated.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.yellow)
                .symbolRenderingMode(.multicolor)
            }

            DatePicker(
                "Starts",
                selection: $viewModel.startDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .confidence(viewModel.confidenceLevel(for: "date"))
            .onChange(of: viewModel.startDate) { _, newDate in
                viewModel.touchedFields.insert(.startDate)
                viewModel.touchedConfidenceFields.insert("date")
                // Keep weekday picker in sync with whatever date was chosen
                viewModel.weekday = WeekdayOption.from(date: newDate)
                // Nudge end date forward if it's no longer after start
                if viewModel.hasEndDate && viewModel.endDate <= newDate {
                    viewModel.endDate = newDate.addingTimeInterval(3_600)
                }
            }

            if let err = viewModel.visibleError(for: .startDate) {
                Text(err).font(.caption).foregroundStyle(.red)
            }

            Toggle("Has end time", isOn: $viewModel.hasEndDate)

            if viewModel.hasEndDate {
                DatePicker(
                    "Ends",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .onChange(of: viewModel.endDate) { _, _ in
                    viewModel.touchedFields.insert(.endDate)
                }

                if let err = viewModel.visibleError(for: .endDate) {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
        } header: {
            Label("Date & Time", systemImage: "calendar.badge.clock")
        }
    }

    @ViewBuilder
    private var recurrenceSection: some View {
        Section {
            Picker("Repeat", selection: $viewModel.recurrence) {
                ForEach(RecurrenceOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            if viewModel.recurrence == .weekly {
                Picker("Day", selection: $viewModel.weekday) {
                    ForEach(WeekdayOption.allCases) { day in
                        Text(day.displayName).tag(day)
                    }
                }
            }
        } header: {
            Label("Recurrence", systemImage: "arrow.clockwise")
        }
    }

    @ViewBuilder
    private var locationSection: some View {
        Section {
            // Location name (required) — also triggers geocoding when address is empty
            VStack(alignment: .leading, spacing: 4) {
                TextField("Location name (e.g. Lake Harriet Bandshell)",
                          text: $viewModel.locationName)
                    .confidence(viewModel.confidenceLevel(for: "location"))
                    .onChange(of: viewModel.locationName) { _, newVal in
                        viewModel.touchedFields.insert(.locationName)
                        viewModel.touchedConfidenceFields.insert("location")
                        // Only geocode from location name when no explicit address is set
                        if viewModel.address.trimmingCharacters(in: .whitespaces).isEmpty {
                            scheduleGeocode(newVal)
                        }
                    }
                if let err = viewModel.visibleError(for: .locationName) {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }

            // Address (optional) — geocodes to update pin; typing here clears
            // the manual-pin flag so the geocoder is allowed to reposition.
            TextField("Address (optional)", text: $viewModel.address)
                .onChange(of: viewModel.address) { _, newVal in
                    userManuallyPinned = false
                    let query = newVal.trimmingCharacters(in: .whitespaces)
                    scheduleGeocode(query.isEmpty ? viewModel.locationName : query)
                }

            Text("Tap the map to set the exact pin location")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Interactive map: tap anywhere to reposition the pin.
            // SpatialTapGesture fires alongside Map's built-in pan/zoom recognizers
            // (.simultaneousGesture) and provides the tap's CGPoint in the Map's
            // local coordinate space — which MapReader.proxy.convert() needs.
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(
                            latitude:  viewModel.latitude,
                            longitude: viewModel.longitude
                        )
                    ) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(viewModel.category.color)
                            .allowsHitTesting(false)
                    }
                    .annotationTitles(.hidden)
                }
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard let coord = proxy.convert(value.location, from: .local) else { return }
                            userManuallyPinned = true
                            viewModel.latitude  = coord.latitude
                            viewModel.longitude = coord.longitude
                            withAnimation {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: coord,
                                    latitudinalMeters: 600,
                                    longitudinalMeters: 600
                                ))
                            }
                        }
                )
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            // Register latitude/longitude in the standard @ViewBuilder tracking context.
            // MapContentBuilder closures may not participate in @Observable tracking,
            // so the annotation won't update unless we also read the properties here.
            .onChange(of: viewModel.latitude)  { _, _ in }
            .onChange(of: viewModel.longitude) { _, _ in }
            // Flush the map to the cell edges for a wider feel
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Label("Location", systemImage: "mappin.and.ellipse")
        }
    }

    @ViewBuilder
    private var pricingSection: some View {
        Section {
            Toggle("Free event", isOn: $viewModel.isFree)

            if !viewModel.isFree {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("Price", text: $viewModel.priceString)
                            .keyboardType(.decimalPad)
                            .onChange(of: viewModel.priceString) { _, _ in
                                viewModel.touchedFields.insert(.price)
                                viewModel.touchedConfidenceFields.insert("price")
                            }
                    }
                    .confidence(viewModel.confidenceLevel(for: "price"))
                    if let err = viewModel.visibleError(for: .price) {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
            }
        } header: {
            Label("Pricing", systemImage: "dollarsign.circle")
        }
    }

    @ViewBuilder
    private var organizerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Your name or organization", text: $viewModel.organizerName)
                    .onChange(of: viewModel.organizerName) { _, _ in
                        viewModel.touchedFields.insert(.organizerName)
                    }
                if let err = viewModel.visibleError(for: .organizerName) {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }

            TextField("Email, phone, or @handle (optional)",
                      text: $viewModel.organizerContact)
        } header: {
            Label("Organizer", systemImage: "person.circle")
        }
    }

    // MARK: - Helpers

    private func centreMapOnDefault() {
        let center = CLLocationCoordinate2D(
            latitude:  viewModel.latitude,
            longitude: viewModel.longitude
        )
        cameraPosition = .region(MKCoordinateRegion(
            center: center,
            latitudinalMeters: 2_000,
            longitudinalMeters: 2_000
        ))
    }

    /// Debounced forward geocode via CLGeocoder.
    /// Waits 800 ms after the last keystroke, resolves the query string to
    /// coordinates, and repositions both the ViewModel pin and the map camera.
    /// Skipped entirely when the user has manually tapped to place the pin.
    private func scheduleGeocode(_ query: String) {
        geocodeTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !userManuallyPinned else {
            print("[Geocoder] Skipped — user manually pinned")
            return
        }

        geocodeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }

            print("[Geocoder] Geocoding: \"\(trimmed)\"")
            let geocoder = CLGeocoder()
            let placemarks = try? await geocoder.geocodeAddressString(trimmed)

            guard !Task.isCancelled else { return }
            guard let location = placemarks?.first?.location else {
                print("[Geocoder] No result for: \"\(trimmed)\"")
                return
            }

            print("[Geocoder] Result: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("🗺 geocoded '\(trimmed)' → \(location.coordinate)")
            viewModel.latitude  = location.coordinate.latitude
            viewModel.longitude = location.coordinate.longitude
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                ))
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
