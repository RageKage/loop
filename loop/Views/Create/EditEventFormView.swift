import SwiftUI

/// Thin wrapper that presents CreateEventFormView in edit mode.
/// All form state, validation, geocoding, and recurrence logic live in
/// CreateEventViewModel (init(editing:) path); this view just sets the entry point.
struct EditEventFormView: View {
    let event: Event
    let onSaved: (String) -> Void

    var body: some View {
        CreateEventFormView(editing: event, onSaved: onSaved)
    }
}
