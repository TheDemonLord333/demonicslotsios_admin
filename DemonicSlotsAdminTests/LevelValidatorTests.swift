//
//  LevelValidatorTests.swift
//  DemonicSlotsAdminTests
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct LevelValidatorTests {
    @Test func clampLeavesInRangeValuesUnchanged() {
        #expect(LevelValidator.clamp(1) == 1)
        #expect(LevelValidator.clamp(50) == 50)
        #expect(LevelValidator.clamp(100) == 100)
    }

    @Test func clampCapsValuesBelowRange() {
        #expect(LevelValidator.clamp(0) == 1)
        #expect(LevelValidator.clamp(-10) == 1)
    }

    @Test func clampCapsValuesAboveRange() {
        #expect(LevelValidator.clamp(101) == 100)
        #expect(LevelValidator.clamp(9999) == 100)
    }
}
