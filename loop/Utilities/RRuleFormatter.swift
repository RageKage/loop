/// Minimal RRULE → human-readable string converter.
/// Covers the subset of rules that the Loop create-event form produces.
/// Full RRULE parsing (UNTIL, COUNT, BYMONTHDAY, etc.) is out of scope.
extension String {

    var rruleDisplayString: String? {
        // Build a key/value dictionary from the semicolon-delimited RRULE tokens.
        var parts: [String: String] = [:]
        for token in split(separator: ";") {
            let kv = token.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { parts[String(kv[0])] = String(kv[1]) }
        }

        let freq     = parts["FREQ"] ?? ""
        let byday    = parts["BYDAY"] ?? ""
        let interval = parts["INTERVAL"].flatMap(Int.init) ?? 1

        switch freq {
        case "DAILY":
            return interval == 1 ? "Every day" : "Every \(interval) days"

        case "WEEKLY":
            let dayNames: [String] = byday.split(separator: ",").compactMap { abbrev in
                switch abbrev {
                case "MO": return "Monday"
                case "TU": return "Tuesday"
                case "WE": return "Wednesday"
                case "TH": return "Thursday"
                case "FR": return "Friday"
                case "SA": return "Saturday"
                case "SU": return "Sunday"
                default:   return nil
                }
            }
            let dayString = dayNames.isEmpty ? "week" : dayNames.joined(separator: ", ")
            return interval == 1
                ? "Every \(dayString)"
                : "Every \(interval) weeks on \(dayString)"

        case "MONTHLY":
            return interval == 1 ? "Every month" : "Every \(interval) months"

        case "YEARLY":
            return "Every year"

        default:
            return nil
        }
    }
}
