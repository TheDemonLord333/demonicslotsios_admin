//
//  DemonicDateParser.swift
//  DemonicSlotsAdmin
//
//  Robust, crash-free ISO-8601 parsing. Tries fractional-seconds first
//  (the backend's usual format), then falls back to whole seconds, and
//  finally gives up gracefully by returning nil.
//

import Foundation

enum DemonicDateParser {
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let withoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parses an ISO-8601 date string, returning `nil` instead of throwing
    /// or crashing for `nil`, empty, or malformed input.
    static func parse(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        if let date = withFractionalSeconds.date(from: string) { return date }
        if let date = withoutFractionalSeconds.date(from: string) { return date }
        return nil
    }
}
