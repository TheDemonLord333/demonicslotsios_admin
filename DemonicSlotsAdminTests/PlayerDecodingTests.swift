//
//  PlayerDecodingTests.swift
//  DemonicSlotsAdminTests
//

import Testing
import Foundation
@testable import DemonicSlotsAdmin

@MainActor
struct PlayerDecodingTests {
    @Test func decodesFullPlayer() throws {
        let json = """
        {"username":"Alice","coinBalance":1200,"createdAt":"2026-01-01T10:00:00.000Z","updatedAt":"2026-01-05T12:30:00Z","adminRevision":4}
        """.data(using: .utf8)!

        let player = try JSONDecoder().decode(Player.self, from: json)

        #expect(player.username == "Alice")
        #expect(player.coinBalance == 1200)
        #expect(player.adminRevision == 4)
        #expect(player.createdAt != nil)
        #expect(player.updatedAt != nil)
    }

    @Test func toleratesMissingOptionalMetadata() throws {
        let json = """
        {"username":"Bob","coinBalance":0}
        """.data(using: .utf8)!

        let player = try JSONDecoder().decode(Player.self, from: json)

        #expect(player.username == "Bob")
        #expect(player.coinBalance == 0)
        #expect(player.createdAt == nil)
        #expect(player.updatedAt == nil)
        #expect(player.adminRevision == nil)
    }

    @Test func toleratesMalformedOptionalDateWithoutFailing() throws {
        let json = """
        {"username":"Carl","coinBalance":50,"createdAt":"not-a-real-date","adminRevision":2}
        """.data(using: .utf8)!

        let player = try JSONDecoder().decode(Player.self, from: json)

        #expect(player.username == "Carl")
        #expect(player.createdAtRaw == "not-a-real-date")
        #expect(player.createdAt == nil)
        #expect(player.adminRevision == 2)
    }

    @Test func toleratesWrongTypedOptionalFieldWithoutFailing() throws {
        let json = """
        {"username":"Dana","coinBalance":10,"adminRevision":"not-a-number"}
        """.data(using: .utf8)!

        let player = try JSONDecoder().decode(Player.self, from: json)

        #expect(player.username == "Dana")
        #expect(player.adminRevision == nil)
    }

    @Test func decodesArrayOfPlayers() throws {
        let json = """
        [{"username":"A","coinBalance":1},{"username":"B","coinBalance":2}]
        """.data(using: .utf8)!

        let players = try JSONDecoder().decode([Player].self, from: json)

        #expect(players.count == 2)
        #expect(players.map(\.username) == ["A", "B"])
    }

    @Test func missingRequiredFieldThrows() {
        let json = """
        {"coinBalance":10}
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(Player.self, from: json)
        }
    }
}
