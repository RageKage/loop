import Foundation
import UIKit

// MARK: - ExtractedEvent DTO

/// Throwaway data-transfer object returned by ClaudeVisionService.
/// Maps to CreateEventViewModel fields; NOT a SwiftData model.
struct ExtractedEvent {
    var title:           String
    var description:     String
    var startDate:       Date?
    var endDate:         Date?
    var recurrenceRule:  String?
    var locationName:    String
    var address:         String?
    var isFree:          Bool
    var price:           Double?
    var organizerName:   String?
    var category:        EventCategory
    var confidence:      [ConfidenceField: ConfidenceLevel]
    var isEventPoster:   Bool   // false → Claude says this isn't an event poster
}

enum ConfidenceLevel: String, Decodable {
    case low, medium, high
}

enum ConfidenceField: String, Hashable {
    case title, description, startDate, endDate, recurrenceRule
    case locationName, address, price, organizerName, category
}

// MARK: - Errors

enum ScanError: LocalizedError {
    case noAPIKey
    case notEventPoster
    case networkError(Error)
    case httpError(Int)
    case parseFailure
    case rateLimited          // Anthropic 429
    case serverError          // Anthropic 5xx

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Claude API key not configured. Go to Settings → Developer to add it."
        case .notEventPoster:
            return "This doesn't look like an event poster. Try a clearer photo, or enter the event manually."
        case .networkError:
            return "Couldn't connect. Check your internet and try again."
        case .httpError(401), .httpError(403):
            return "API key issue. Check Settings → Developer."
        case .httpError(429), .rateLimited:
            return "Too many requests. Try again in a minute."
        case .httpError(let code) where code >= 500:
            return "Anthropic's servers had a hiccup. Try again in a moment."
        case .httpError:
            return "Unexpected error. Try again."
        case .parseFailure:
            return "Couldn't read that poster. Try a clearer photo, or enter it manually."
        case .serverError:
            return "Anthropic's servers had a hiccup. Try again in a moment."
        }
    }
}

// MARK: - ClaudeVisionService

/// Sends a compressed poster image to Claude Haiku as a base64 vision block
/// and parses the structured JSON response into an ExtractedEvent.
actor ClaudeVisionService {
    static let shared = ClaudeVisionService()

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model    = "claude-haiku-4-5-20251001"
    private let session  = URLSession.shared

    // MARK: - Public API

    func extractEvent(from imageData: Data, apiKey: String) async throws -> ExtractedEvent {
        let compressed = compress(imageData)
        let b64        = compressed.base64EncodedString()

        let body = buildRequestBody(base64Image: b64)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json",       forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,                   forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",             forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ScanError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw ScanError.parseFailure }
        switch http.statusCode {
        case 200:        break
        case 429:        throw ScanError.rateLimited
        case 500...:     throw ScanError.serverError
        default:         throw ScanError.httpError(http.statusCode)
        }

        return try parseResponse(data)
    }

    // MARK: - Mock (for development without real API calls)

    func mockExtractEvent() async throws -> ExtractedEvent {
        // Simulate network delay
        try await Task.sleep(for: .seconds(2))
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        let start    = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow)!
        return ExtractedEvent(
            title:          "Summer Jazz in the Park",
            description:    "An evening of live jazz with local artists. Bring a blanket and enjoy the sunset. Food and drinks available on site.",
            startDate:      start,
            endDate:        start.addingTimeInterval(7200),
            recurrenceRule: nil,
            locationName:   "Minnehaha Park Pavilion",
            address:        "4801 Minnehaha Ave, Minneapolis, MN 55417",
            isFree:         false,
            price:          12.0,
            organizerName:  "Minneapolis Parks Foundation",
            category:       .music,
            confidence: [
                .title:        .high,
                .description:  .medium,
                .startDate:    .high,
                .endDate:      .medium,
                .locationName: .high,
                .address:      .medium,
                .price:        .high,
                .organizerName:.low,
                .category:     .high,
            ],
            isEventPoster: true
        )
    }

    // MARK: - Private helpers

    private func compress(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        if scale >= 1 { return data }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized  = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.82) ?? data
    }

    private func buildRequestBody(base64Image: String) -> [String: Any] {
        let systemPrompt = """
        You are an event-detail extractor. You receive a photo of an event poster and return \
        ONLY a valid JSON object — no markdown, no explanation, no surrounding text.
        """

        let userPrompt = """
        Extract event details from this poster photo and return ONLY a JSON object with these fields:

        {
          "is_event_poster": true,
          "title": "string (max 80 chars)",
          "description": "string (max 500 chars, summarize if needed)",
          "startDate": "ISO8601 datetime string or null",
          "endDate": "ISO8601 datetime string or null",
          "recurrenceRule": "RRULE string (e.g. FREQ=WEEKLY;BYDAY=SA) or null",
          "locationName": "string or null",
          "address": "string or null",
          "isFree": true,
          "price": null,
          "organizerName": "string or null",
          "category": "one of: fitness, books, social, music, food, outdoors, kids, other",
          "confidence": {
            "title": "high|medium|low",
            "description": "high|medium|low",
            "startDate": "high|medium|low",
            "endDate": "high|medium|low",
            "recurrenceRule": "high|medium|low",
            "locationName": "high|medium|low",
            "address": "high|medium|low",
            "price": "high|medium|low",
            "organizerName": "high|medium|low",
            "category": "high|medium|low"
          }
        }

        If this is not an event poster, return: {"is_event_poster": false}

        For dates, use the current year if not specified. If no year is visible, assume the \
        nearest future occurrence of the date shown. Return ISO8601 with timezone offset \
        if visible, otherwise use local time (no Z suffix).
        """

        return [
            "model": model,
            "max_tokens": 1024,
            "temperature": 0.2,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type":       "base64",
                                "media_type": "image/jpeg",
                                "data":       base64Image,
                            ],
                        ],
                        [
                            "type": "text",
                            "text": userPrompt,
                        ],
                    ],
                ]
            ],
        ]
    }

    private func parseResponse(_ data: Data) throws -> ExtractedEvent {
        // Claude's response wraps the JSON in a messages content block.
        guard
            let outer   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = (outer["content"] as? [[String: Any]])?.first,
            let text    = content["text"] as? String,
            // Strip any accidental markdown fences
            let jsonData = cleanJSON(text).data(using: .utf8),
            let parsed  = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { throw ScanError.parseFailure }

        let isEventPoster = parsed["is_event_poster"] as? Bool ?? true
        guard isEventPoster else { throw ScanError.notEventPoster }

        let conf = parseConfidence(parsed["confidence"] as? [String: String] ?? [:])

        return ExtractedEvent(
            title:          parsed["title"]        as? String ?? "",
            description:    parsed["description"]  as? String ?? "",
            startDate:      parseDate(parsed["startDate"]),
            endDate:        parseDate(parsed["endDate"]),
            recurrenceRule: parsed["recurrenceRule"] as? String,
            locationName:   parsed["locationName"] as? String ?? "",
            address:        parsed["address"]      as? String,
            isFree:         parsed["isFree"]       as? Bool   ?? true,
            price:          parsed["price"]        as? Double,
            organizerName:  parsed["organizerName"] as? String,
            category:       parseCategory(parsed["category"] as? String),
            confidence:     conf,
            isEventPoster:  true
        )
    }

    private func cleanJSON(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            s = s.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
            s = s.components(separatedBy: "```").first ?? s
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDate(_ value: Any?) -> Date? {
        guard let str = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: str) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: str) { return d }
        // Try without timezone (local time)
        let plain = DateFormatter()
        plain.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return plain.date(from: str)
    }

    private func parseCategory(_ raw: String?) -> EventCategory {
        guard let raw else { return .other }
        return EventCategory(rawValue: raw) ?? .other
    }

    private func parseConfidence(_ dict: [String: String]) -> [ConfidenceField: ConfidenceLevel] {
        var result: [ConfidenceField: ConfidenceLevel] = [:]
        let map: [String: ConfidenceField] = [
            "title": .title, "description": .description,
            "startDate": .startDate, "endDate": .endDate,
            "recurrenceRule": .recurrenceRule, "locationName": .locationName,
            "address": .address, "price": .price,
            "organizerName": .organizerName, "category": .category,
        ]
        for (key, field) in map {
            if let rawLevel = dict[key], let level = ConfidenceLevel(rawValue: rawLevel) {
                result[field] = level
            }
        }
        return result
    }
}
