//
//  UsernameValidatorTests.swift
//  DemonicSlotsAdminTests
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct UsernameValidatorTests {
    @Test func acceptsValidUsernames() {
        #expect(UsernameValidator.validate("Bob") == "Bob")
        #expect(UsernameValidator.validate("demon_slayer_99") == "demon_slayer_99")
        #expect(UsernameValidator.validate("  Alice  ") == "Alice")
    }

    @Test func rejectsTooShortUsernames() {
        #expect(UsernameValidator.validate("ab") == nil)
        #expect(UsernameValidator.validate("") == nil)
    }

    @Test func rejectsTooLongUsernames() {
        let tooLong = String(repeating: "a", count: 21)
        #expect(UsernameValidator.validate(tooLong) == nil)
    }

    @Test func acceptsBoundaryLengths() {
        #expect(UsernameValidator.validate("abc") == "abc")
        #expect(UsernameValidator.validate(String(repeating: "a", count: 20)) == String(repeating: "a", count: 20))
    }

    @Test func rejectsDisallowedCharacters() {
        #expect(UsernameValidator.validate("bad name") == nil)
        #expect(UsernameValidator.validate("bad-name") == nil)
        #expect(UsernameValidator.validate("bad@name") == nil)
        #expect(UsernameValidator.validate("böse") == nil)
    }
}
