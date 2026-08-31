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
    var updateBalanceResult: Result<Player, Error>?
    var renameUsernameResult: Result<Player, Error>?

    private(set) var fetchPlayersCallCount = 0
    private(set) var lastUpdateBalanceId: String?
    private(set) var lastUpdateBalanceValue: Int?
    private(set) var lastRenameId: String?
    private(set) var lastRenameUsername: String?

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

    func updateBalance(id: String, balance: Int) async throws -> Player {
        lastUpdateBalanceId = id
        lastUpdateBalanceValue = balance
        guard let updateBalanceResult else {
            throw APIError.playerNotFound
        }
        return try updateBalanceResult.get()
    }

    func renameUsername(id: String, newUsername: String) async throws -> Player {
        lastRenameId = id
        lastRenameUsername = newUsername
        guard let renameUsernameResult else {
            throw APIError.playerNotFound
        }
        return try renameUsernameResult.get()
    }
}
