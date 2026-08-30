//
//  DemonicDateParserTests.swift
//  DemonicSlotsAdminTests
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct DemonicDateParserTests {
    @Test func parsesFractionalSecondsISO8601() {
        #expect(DemonicDateParser.parse("2026-01-01T10:00:00.123Z") != nil)
    }

    @Test func parsesPlainISO8601WithoutFractionalSeconds() {
        #expect(DemonicDateParser.parse("2026-01-01T10:00:00Z") != nil)
    }

    @Test func parsesWithTimezoneOffset() {
        #expect(DemonicDateParser.parse("2026-01-01T10:00:00.500+02:00") != nil)
    }

    @Test func returnsNilForMalformedInput() {
        #expect(DemonicDateParser.parse("not-a-date") == nil)
    }

    @Test func returnsNilForNilInput() {
        #expect(DemonicDateParser.parse(nil) == nil)
    }

    @Test func returnsNilForEmptyString() {
        #expect(DemonicDateParser.parse("") == nil)
    }
}
