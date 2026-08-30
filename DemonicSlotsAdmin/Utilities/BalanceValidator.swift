//
//  BalanceValidator.swift
//  DemonicSlotsAdmin
//
//  Validates balance input from PlayerDetailView: must be a non-negative,
//  non-decimal integer that fits in Int (protects against overflow).
//

import Foundation

enum BalanceValidator {
    /// Returns the validated non-negative integer, or `nil` when `raw` is
    /// empty, negative, decimal, non-numeric, or too large to fit in `Int`.
    static func validate(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        guard let value = Int(trimmed) else { return nil }
        return value
    }
}
