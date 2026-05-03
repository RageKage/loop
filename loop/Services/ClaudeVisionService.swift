import Foundation

enum ClaudeVisionError: Error, LocalizedError {
    case noAPIKey
    case networkFailure(underlying: Error)
    case apiError(statusCode: Int, message: String)
    case invalidResponse
    case notAnEventPoster
    case refused(reason: String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key set. Add one in Settings → Developer."
        case .networkFailure:
            return "Couldn't reach Claude. Check your internet."
        case .apiError(let code, let message):
            return "Claude API returned \(code): \(message)"
        case .invalidResponse:
            return "Couldn't read Claude's response."
        case .notAnEventPoster:
            return "This doesn't look like an event poster."
        case .refused:
            return "Claude declined to extract this event."
        }
    }
}

enum ClaudeVisionService {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private static func buildExtractionPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd (EEEE)"
        formatter.locale = Locale(identifier: "en_US")
        let today = formatter.string(from: Date())

        return """
        You are extracting event details from a poster image for a local community events app focused on free and low-cost third-place gatherings (run clubs, book clubs, meetups, concerts, workshops, farmers markets).

        Today's date: \(today)

        Return ONLY a JSON object. No prose, no markdown fences, no explanation. The JSON must match this schema:

        {
          "is_event_poster": boolean,
          "refused": boolean,
          "refusal_reason": string or null,
          "title": string or null,
          "description": string or null,
          "start_iso": string or null,
          "end_iso": string or null,
          "recurrence_rrule": string or null,
          "location_name": string or null,
          "address": string or null,
          "is_free": boolean or null,
          "price_usd": number or null,
          "organizer_name": string or null,
          "category": one of ["fitness","books","social","music","food","outdoors","kids","other"] or null,
          "confidence": { "title": "high|medium|low", "date": "high|medium|low", "location": "high|medium|low", "price": "high|medium|low" }
        }

        CONFIDENCE RUBRIC — score each field honestly before writing the JSON:
        - "high": The field is directly readable from the image — clear text, unambiguous, you are reading it not interpreting it. A specific date and time are explicitly printed. A venue name or full address is clearly shown. A price is explicitly stated. Do NOT assign high if you had to interpret or infer anything about the field.
        - "medium": The field is present but required light interpretation. A date shown without a year. A venue name present but no address. A price implied but not stated outright. Text that is partially obscured, low-contrast, or slightly cropped but still readable.
        - "low": You inferred this field from context rather than reading it directly. A category guessed from the event's general vibe rather than an explicit label. A time like "evening" with no specific hour. An organizer name not explicitly credited on the poster. Any field where you are genuinely uncertain about the value.

        CONFIDENCE ANTI-PATTERNS — do not make these mistakes:
        - Do not default to "high". If you would not bet money on the exact value, it is not high.
        - If the image is blurry, low-resolution, glare-affected, or partially cropped, default to "medium" across all affected fields.
        - If you are inferring a field from context (e.g. guessing the category from the event's vibe rather than reading it on the poster), that is "low", not "medium".
        - It is expected and correct for a single scan to return a mix of high, medium, and low values across fields. That is accurate behavior.
        - Returning "high" on every field is almost never correct for a real-world poster photo taken on a phone.

        DATE RULES — ambiguous dates must resolve to the future:
        - Today's date is provided at the top of this prompt. Use it as the anchor for all date resolution.
        - If the poster shows a date without a year (e.g. "July 28", "Friday Aug 12", "every Saturday"), resolve it to the next future occurrence on or after today. Never resolve to a past date.
        - If you resolve a year-ambiguous date, that field's confidence is "medium" at most — never "high".
        - If no timezone is shown, assume America/Chicago.
        - All dates must be ISO 8601 with a timezone offset.

        EXTRACTION RULES:
        - If the image is not an event poster (random photo, meme, document), return {"is_event_poster": false} and null for everything else.
        - If the event appears political, protest-related, or hate-based, return {"refused": true, "refusal_reason": "out_of_scope"} and null for everything else. Loop is for community gatherings, not political organizing.
        - Never guess. If a field is unclear, return null for that field rather than inventing a value.
        - Leave address null unless a full street address is visible on the poster. Location name alone is fine.
        - If the poster shows "Free" or has no price mentioned at all, is_free = true, price_usd = null.
        - If a price is shown, is_free = false, price_usd = the numeric value.
        - Recurrence: use RRULE format (e.g. "FREQ=WEEKLY;BYDAY=SA"). Only set if the poster clearly states recurrence like "every Saturday".
        """
    }

    static func extractEvent(from imageData: Data) async throws -> ExtractedEvent {
        guard let apiKey = KeychainService.loadWithDevFallback() else {
            throw ClaudeVisionError.noAPIKey
        }

        let base64Image = imageData.base64EncodedString()

        let body: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 1024,
            "temperature": 0.2,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": buildExtractionPrompt()
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw ClaudeVisionError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeVisionError.networkFailure(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeVisionError.invalidResponse
        }

        guard http.statusCode == 200 else {
            let message = errorMessage(for: http.statusCode, data: data)
            throw ClaudeVisionError.apiError(statusCode: http.statusCode, message: message)
        }

        return try parseResponse(data: data)
    }

    private static func errorMessage(for statusCode: Int, data: Data) -> String {
        switch statusCode {
        case 401, 403:
            return "Invalid API key."
        case 429:
            return "Rate limit — try again in a moment."
        case 500...599:
            return "Claude's servers had a hiccup."
        default:
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let msg = error["message"] as? String {
                return msg
            }
            return "HTTP \(statusCode)"
        }
    }

    private static func parseResponse(data: Data) throws -> ExtractedEvent {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first = content.first,
            let text = first["text"] as? String
        else {
            throw ClaudeVisionError.invalidResponse
        }

        let cleaned = stripMarkdownFences(text)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ClaudeVisionError.invalidResponse
        }

        let event: ExtractedEvent
        do {
            event = try JSONDecoder().decode(ExtractedEvent.self, from: jsonData)
        } catch {
            throw ClaudeVisionError.invalidResponse
        }

        if !event.isEventPoster {
            throw ClaudeVisionError.notAnEventPoster
        }
        if event.refused {
            throw ClaudeVisionError.refused(reason: event.refusalReason ?? "unknown")
        }

        return event
    }

    private static func stripMarkdownFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            if let range = result.range(of: "\n") {
                result = String(result[range.upperBound...])
            }
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
}
