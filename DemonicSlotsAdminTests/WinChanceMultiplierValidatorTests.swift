//
//  WinChanceMultiplierValidatorTests.swift
//  DemonicSlotsAdminTests
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct WinChanceMultiplierValidatorTests {
    @Test func clampLeavesInRangeValuesUnchanged() {
        #expect(WinChanceMultiplierValidator.clamp(0.10) == 0.10)
        #expect(WinChanceMultiplierValidator.clamp(1.0) == 1.0)
        #expect(WinChanceMultiplierValidator.clamp(2.0) == 2.0)
    }

    @Test func clampCapsValuesBelowRange() {
        #expect(WinChanceMultiplierValidator.clamp(0) == 0.10)
        #expect(WinChanceMultiplierValidator.clamp(-5) == 0.10)
    }

    @Test func clampCapsValuesAboveRange() {
        #expect(WinChanceMultiplierValidator.clamp(2.5) == 2.0)
        #expect(WinChanceMultiplierValidator.clamp(99) == 2.0)
    }
}
