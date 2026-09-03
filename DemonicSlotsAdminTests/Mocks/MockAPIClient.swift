//
//  MockAPIClient.swift
//  DemonicSlotsAdminTests
//
//  In-memory AdminAPIClientProtocol implementation for testing view
//  models without any networking.
//

import Foundation
@testable import DemonicSlotsAdmin

@MainActor
final class MockAPIClient: AdminAPIClientProtocol {
    var playersResult: Result<[Player], Error> = .success([])
    var updatePlayerResult: Result<Player, Error>?

    private(set) var fetchPlayersCallCount = 0
    private(set) var lastUpdatePlayerId: String?
    private(set) var lastUpdatePlayerFields: PlayerUpdateFields?

    func fetchPlayers() async throws -> [Player] {
        fetchPlayersCallCount += 1
        return try playersResult.get()
    }

    func fetchPlayer(id: String) async throws -> Player {
        let players = try playersResult.get()
        guard let player = players.first(where: { $0.id == id }) else {
            throw APIError.playerNotFound
        }
        return player
    }

    func updatePlayer(id: String, fields: PlayerUpdateFields) async throws -> Player {
        lastUpdatePlayerId = id
        lastUpdatePlayerFields = fields
        guard let updatePlayerResult else {
            throw APIError.playerNotFound
        }
        return try updatePlayerResult.get()
    }
}
