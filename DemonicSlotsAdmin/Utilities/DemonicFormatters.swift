//
//  DemonicFormatters.swift
//  DemonicSlotsAdmin
//
//  German-locale number and date formatting, matching the reference
//  web app's `Intl.NumberFormat('de-DE')` / `Intl.DateTimeFormat('de-DE')`.
//

import Foundation

enum DemonicFormatters {
    private static let coinNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let multiplierFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// e.g. 1000 -> "1.000"
    static func formatCoins(_ value: Int) -> String {
        coinNumberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// e.g. 1.0 -> "1,00" (caller appends "×"). Always exactly two
    /// fraction digits, matching the web app's multiplier formatter.
    static func formatMultiplier(_ value: Double) -> String {
        multiplierFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    /// Formats a parsed date in German medium/short style. Falls back to the
    /// raw server string when the date couldn't be parsed, and finally to
    /// an em dash when there is nothing at all — mirroring the web app's
    /// `formatDate` helper.
    static func formatDate(_ date: Date?, fallbackRaw: String? = nil) -> String {
        if let date {
            return dateTimeFormatter.string(from: date)
        }
        if let fallbackRaw, !fallbackRaw.isEmpty {
            return fallbackRaw
        }
        return "—"
    }
}
