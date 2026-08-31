//
//  UsernameValidator.swift
//  DemonicSlotsAdmin
//
//  Client-side mirror of the backend's username rule (see
//  demonicslotsweb_admin's PATCH /api/admin/players/:id/username):
//  3–20 characters, letters/digits/underscore only. The server still
//  re-validates (and enforces uniqueness) — this just avoids a round
//  trip for obviously-invalid input.
//

import Foundation

enum UsernameValidator {
    private static let allowedLength = 3...20

    /// Returns the trimmed, validated username, or `nil` when it's the
    /// wrong length or contains characters other than ASCII letters,
    /// digits, or `_`.
    static func validate(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard allowedLength.contains(trimmed.count) else { return nil }
        guard trimmed.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }) else {
            return nil
        }
        return trimmed
    }
}
