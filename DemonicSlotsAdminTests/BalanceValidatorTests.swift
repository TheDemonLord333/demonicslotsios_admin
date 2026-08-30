//
//  BalanceValidatorTests.swift
//  DemonicSlotsAdminTests
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct BalanceValidatorTests {
    @Test func acceptsNonNegativeIntegers() {
        #expect(BalanceValidator.validate("0") == 0)
        #expect(BalanceValidator.validate("1000") == 1000)
        #expect(BalanceValidator.validate("  42  ") == 42)
    }

    @Test func rejectsEmptyOrWhitespaceInput() {
        #expect(BalanceValidator.validate("") == nil)
        #expect(BalanceValidator.validate("   ") == nil)
    }

    @Test func rejectsNegativeNumbers() {
        #expect(BalanceValidator.validate("-5") == nil)
        #expect(BalanceValidator.validate("-0") == nil)
    }

    @Test func rejectsDecimalNumbers() {
        #expect(BalanceValidator.validate("10.5") == nil)
        #expect(BalanceValidator.validate("10,5") == nil)
    }

    @Test func rejectsNonNumericInput() {
        #expect(BalanceValidator.validate("abc") == nil)
        #expect(BalanceValidator.validate("12a") == nil)
        #expect(BalanceValidator.validate("1e10") == nil)
    }

    @Test func rejectsIntegerOverflow() {
        #expect(BalanceValidator.validate("999999999999999999999999999999") == nil)
    }

    @Test func acceptsLeadingZeros() {
        #expect(BalanceValidator.validate("007") == 7)
    }
}
