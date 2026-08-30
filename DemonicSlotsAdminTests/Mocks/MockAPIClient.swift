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

    private(set) var fetchPlayersCallCount = 0
    private(set) var lastUpdateBalanceUsername: String?
    private(set) var lastUpdateBalanceValue: Int?

    func fetchPlayers() async throws -> [Player] {
        fetchPlayersCallCount += 1
        return try playersResult.get()
    }

    func fetchPlayer(username: String) async throws -> Player {
        let players = try playersResult.get()
        guard let player = players.first(where: { $0.username == username }) else {
            throw APIError.playerNotFound
        }
        return player
    }

    func updateBalance(username: String, balance: Int) async throws -> Player {
        lastUpdateBalanceUsername = username
        lastUpdateBalanceValue = balance
        guard let updateBalanceResult else {
            throw APIError.playerNotFound
        }
        return try updateBalanceResult.get()
    }
}
