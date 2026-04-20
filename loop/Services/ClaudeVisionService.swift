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

    private static let extractionPrompt = """
    You are extracting event details from a poster image for a local community events app focused on free and low-cost third-place gatherings (run clubs, book clubs, meetups, concerts, workshops, farmers markets).

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

    Confidence scoring (be CONSERVATIVE, not generous):
    - "high": The field is clearly readable on the poster with no ambiguity. A specific date and time are printed. A specific venue name or address is shown. A price is explicitly stated.
    - "medium": The field is readable but required some interpretation. A date was shown without a year so you assumed the next occurrence. A venue name was shown but no address. A price was implied but not explicitly stated.
    - "low": You inferred this field from context rather than reading it directly. A category you assigned based on the event's general vibe. A time like "evening" with no specific hour. An organizer name that wasn't explicitly credited.

    Default to "medium" when in doubt. Only return "high" when the poster text is unambiguous. If you're uncertain, choose "low".

    Rules:
    - If the image is not an event poster (random photo, meme, document), return {"is_event_poster": false} and null for everything else.
    - If the event appears political, protest-related, or hate-based, return {"refused": true, "refusal_reason": "out_of_scope"} and null for everything else. Loop is for community gatherings, not political organizing.
    - Dates must be ISO 8601 with timezone. If no year is visible, assume the next occurrence from today. If no timezone is shown, assume America/Chicago.
    - Never guess. If a field is unclear, return null for that field rather than inventing a value.
    - Leave address null unless a full street address is visible on the poster. Location name alone is fine.
    - If the poster shows "Free" or has no price mentioned at all, is_free = true, price_usd = null.
    - If a price is shown, is_free = false, price_usd = the numeric value.
    - Recurrence: use RRULE format (e.g. "FREQ=WEEKLY;BYDAY=SA"). Only set if the poster clearly states recurrence like "every Saturday".
    """

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
                            "text": extractionPrompt
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
