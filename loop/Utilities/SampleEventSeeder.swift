import Foundation
import SwiftData

/// Inserts realistic Minneapolis sample events on first launch, when the
/// Event store is empty. All seeded events are marked isApproved = true
/// so they pass the Discover tab's @Query filter.
///
/// Distances used by the list sort will be computed from the user's real
/// location or the Minneapolis downtown fallback — either way the events
/// spread across the metro will show meaningful variation.
@MainActor
enum SampleEventSeeder {

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Event>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }
        sampleEvents.forEach { context.insert($0) }
        try? context.save()
    }

    // MARK: - Helpers

    /// Builds a Date for `daysFromNow` days in the future at the given hour:minute.
    private static func date(daysFromNow: Int, hour: Int, minute: Int = 0) -> Date {
        let today    = Calendar.current.startOfDay(for: .now)
        let day      = Calendar.current.date(byAdding: .day, value: daysFromNow, to: today) ?? today
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    /// Convenience factory — reduces repetition in the sample data list below.
    private static func event(
        title: String,
        description: String,
        start: Date,
        durationHours: Double = 1.5,
        recurrence: String? = nil,
        locationName: String,
        lat: Double, lon: Double,
        address: String,
        isFree: Bool = true,
        price: Double? = nil,
        category: EventCategory,
        organizer: String,
        contact: String? = nil
    ) -> Event {
        Event(
            title: title,
            eventDescription: description,
            startDate: start,
            endDate: start.addingTimeInterval(durationHours * 3600),
            recurrenceRule: recurrence,
            locationName: locationName,
            latitude: lat,
            longitude: lon,
            address: address,
            isFree: isFree,
            price: price,
            category: category.rawValue,
            organizerName: organizer,
            organizerContact: contact,
            isApproved: true
        )
    }

    // MARK: - Sample Events
    // Dates are relative to install day, so the data stays fresh.
    // Spread across Minneapolis neighbourhoods; mix of recurring and one-off.

    static var sampleEvents: [Event] {[

        // ── FITNESS ─────────────────────────────────────────────────────────────

        event(
            title: "Lake Harriet Run Club",
            description: "All paces, all vibes. We loop the lake (~3.2 mi) then grab coffee at the Tea House. Meet at the north bandshell — no sign-up, just show up.",
            start: date(daysFromNow: 2, hour: 7),
            durationHours: 1,
            recurrence: "FREQ=WEEKLY;BYDAY=SA",
            locationName: "Lake Harriet Bandshell",
            lat: 44.9217, lon: -93.3075,
            address: "4135 W Lake Harriet Pkwy, Minneapolis, MN 55410",
            category: .fitness,
            organizer: "Lake Harriet Running Group",
            contact: "lhrunclub@example.com"
        ),

        event(
            title: "Free Yoga in Loring Park",
            description: "All-levels outdoor yoga on the great lawn. Bring your own mat. Rain plan: meet under the pavilion. Led by certified instructor Priya Sharma.",
            start: date(daysFromNow: 3, hour: 9),
            durationHours: 1,
            recurrence: "FREQ=WEEKLY;BYDAY=SU",
            locationName: "Loring Park Great Lawn",
            lat: 44.9719, lon: -93.2842,
            address: "1382 Willow St, Minneapolis, MN 55403",
            category: .fitness,
            organizer: "Priya Sharma"
        ),

        // ── SOCIAL ──────────────────────────────────────────────────────────────

        event(
            title: "Northeast Minneapolis Art Walk",
            description: "Explore 30+ studios across the NE Arts District. Free maps at the first stop. Trolley between venues 5–9 PM.",
            start: date(daysFromNow: 2, hour: 14),
            durationHours: 5,
            locationName: "NE Arts District",
            lat: 45.0003, lon: -93.2567,
            address: "Start: 1224 Quincy St NE, Minneapolis, MN 55413",
            category: .social,
            organizer: "NE Minneapolis Arts District",
            contact: "info@neartsdistrict.org"
        ),

        event(
            title: "Stadium Village Trivia Night",
            description: "Seven rounds covering pop culture, Minnesota history, and whatever else our host dreams up. Teams of up to 6. Prizes for top 3. Free to play.",
            start: date(daysFromNow: 5, hour: 19),
            durationHours: 2,
            recurrence: "FREQ=WEEKLY;BYDAY=TU",
            locationName: "Blarney Pub & Grill",
            lat: 44.9750, lon: -93.2330,
            address: "412 14th Ave SE, Minneapolis, MN 55414",
            category: .social,
            organizer: "Stadium Village Trivia Co."
        ),

        event(
            title: "Lyn-Lake Singles Social",
            description: "Low-pressure mingling for Minneapolis singles in their 20s–40s. Name tags, conversation starters, a hosted icebreaker. Two-drink ticket included.",
            start: date(daysFromNow: 8, hour: 19),
            durationHours: 3,
            recurrence: "FREQ=MONTHLY",
            locationName: "Lyn-Lake Tap Room",
            lat: 44.9508, lon: -93.2934,
            address: "2838 Lyndale Ave S, Minneapolis, MN 55408",
            isFree: false, price: 15,
            category: .social,
            organizer: "Lyn-Lake Events",
            contact: "hello@lynlakeevents.com"
        ),

        // ── MUSIC ───────────────────────────────────────────────────────────────

        event(
            title: "Friday Jazz Sessions",
            description: "Live jazz every Friday with local Twin Cities musicians. Full bar and small plates available. Doors 7:30, music at 8. Standing room only most nights — arrive early.",
            start: date(daysFromNow: 1, hour: 20),
            durationHours: 2.5,
            recurrence: "FREQ=WEEKLY;BYDAY=FR",
            locationName: "Icehouse",
            lat: 44.9537, lon: -93.2836,
            address: "2528 Nicollet Ave, Minneapolis, MN 55404",
            isFree: false, price: 12,
            category: .music,
            organizer: "Icehouse MPLS",
            contact: "events@icehousempls.com"
        ),

        event(
            title: "Loring Park Drum Circle",
            description: "Community drum circle open to all. Bring any drum or percussion instrument — or just clap along. All skill levels, all ages welcome.",
            start: date(daysFromNow: 3, hour: 15),
            durationHours: 2,
            recurrence: "FREQ=MONTHLY",
            locationName: "Loring Park Amphitheater",
            lat: 44.9715, lon: -93.2855,
            address: "1382 Willow St, Minneapolis, MN 55403",
            category: .music,
            organizer: "Loring Park Community"
        ),

        // ── FOOD ────────────────────────────────────────────────────────────────

        event(
            title: "Midtown Farmers Market",
            description: "80+ local vendors: produce, baked goods, cheese, eggs, flowers, and hot breakfast. Live music most mornings. Dog-friendly. Rain or shine.",
            start: date(daysFromNow: 1, hour: 7),
            durationHours: 5,
            recurrence: "FREQ=WEEKLY;BYDAY=SA,SU",
            locationName: "Midtown Farmers Market",
            lat: 44.9477, lon: -93.2682,
            address: "2225 E Lake St, Minneapolis, MN 55407",
            category: .food,
            organizer: "Midtown Farmers Market"
        ),

        event(
            title: "Coffee Roasting Workshop",
            description: "Learn the full roasting process from green bean to cup, led by North Loop Roasters' head roaster. Includes a 250g take-home bag of your own roast. Limited to 12.",
            start: date(daysFromNow: 16, hour: 10),
            durationHours: 2.5,
            locationName: "North Loop Roasters",
            lat: 44.9840, lon: -93.2785,
            address: "729 Washington Ave N, Minneapolis, MN 55401",
            isFree: false, price: 28,
            category: .food,
            organizer: "North Loop Roasters",
            contact: "workshop@northloopcoffee.com"
        ),

        // ── BOOKS ───────────────────────────────────────────────────────────────

        event(
            title: "Midtown Book Exchange",
            description: "Bring up to 5 books, swap for others from the community pile. No assigned title — just share what you've been reading. Coffee provided.",
            start: date(daysFromNow: 5, hour: 18, minute: 30),
            durationHours: 1.5,
            recurrence: "FREQ=MONTHLY",
            locationName: "Moon Palace Books",
            lat: 44.9491, lon: -93.2637,
            address: "3032 Minnehaha Ave, Minneapolis, MN 55406",
            category: .books,
            organizer: "Moon Palace Books"
        ),

        // ── OUTDOORS ────────────────────────────────────────────────────────────

        event(
            title: "Minnehaha Falls Morning Hike",
            description: "Easy 2-mile loop through Minnehaha Regional Park, past the falls and down to the Mississippi. Led by a naturalist guide. Dog-friendly. Meet at the main parking lot.",
            start: date(daysFromNow: 9, hour: 8, minute: 30),
            durationHours: 1.5,
            recurrence: "FREQ=WEEKLY;BYDAY=SA",
            locationName: "Minnehaha Regional Park",
            lat: 44.9153, lon: -93.2107,
            address: "4801 Minnehaha Ave, Minneapolis, MN 55417",
            category: .outdoors,
            organizer: "Minneapolis Parks Foundation"
        ),

        // ── KIDS ────────────────────────────────────────────────────────────────

        event(
            title: "Saturday Story Time",
            description: "Stories, songs, and crafts for children ages 2–6. Caregivers welcome. No registration — just show up! Run by the Children's Department every Saturday.",
            start: date(daysFromNow: 9, hour: 11),
            durationHours: 0.75,
            recurrence: "FREQ=WEEKLY;BYDAY=SA",
            locationName: "Minneapolis Central Library",
            lat: 44.9793, lon: -93.2724,
            address: "300 Nicollet Mall, Minneapolis, MN 55401",
            category: .kids,
            organizer: "Hennepin County Library",
            contact: "kids@hclib.org"
        ),

    ]}
}
