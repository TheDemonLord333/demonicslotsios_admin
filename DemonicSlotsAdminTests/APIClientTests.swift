//
//  APIClientTests.swift
//  DemonicSlotsAdminTests
//
//  End-to-end APIClient behavior (request building, headers, decoding)
//  against a mocked URLProtocol — no real network access.
//

import Testing
import Foundation
@testable import DemonicSlotsAdmin

@MainActor
struct APIClientTests {
    private func makeClient(handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) -> APIClient {
        MockURLProtocol.requestHandler = handler
        return APIClient(
            baseURL: URL(string: "https://demonicslots.example.com")!,
            token: "test-token",
            session: MockSession.makeURLSession()
        )
    }

    @Test func fetchPlayersHitsExpectedURLAndAuthHeader() async throws {
        let client = makeClient { request in
            #expect(request.url?.absoluteString == "https://demonicslots.example.com/api/admin/players")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
            let json = "[]".data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let players = try await client.fetchPlayers()
        #expect(players.isEmpty)
    }

    @Test func fetchPlayerEncodesIdInRequestURL() async throws {
        let client = makeClient { request in
            #expect(request.url?.absoluteString.hasSuffix("/api/admin/players/id%20with%20space") == true)
            let json = #"{"id":"id with space","username":"john","coinBalance":10,"adminRevision":1}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let player = try await client.fetchPlayer(id: "id with space")
        #expect(player.username == "john")
        #expect(player.id == "id with space")
    }

    @Test func updateBalanceSendsPatchWithBalanceBody() async throws {
        let client = makeClient { request in
            #expect(request.httpMethod == "PATCH")
            #expect(request.url?.absoluteString.hasSuffix("/api/admin/players/player-1/balance") == true)
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Int]
            #expect(json?["balance"] == 2500)
            let responseJSON = #"{"id":"player-1","username":"Bob","coinBalance":2500,"adminRevision":2}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let player = try await client.updateBalance(id: "player-1", balance: 2500)
        #expect(player.coinBalance == 2500)
        #expect(player.adminRevision == 2)
    }

    @Test func renameUsernameSendsPatchWithUsernameBody() async throws {
        let client = makeClient { request in
            #expect(request.httpMethod == "PATCH")
            #expect(request.url?.absoluteString.hasSuffix("/api/admin/players/player-1/username") == true)
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            #expect(json?["username"] == "NewName")
            let responseJSON = #"{"id":"player-1","username":"NewName","coinBalance":500,"adminRevision":3}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let player = try await client.renameUsername(id: "player-1", newUsername: "NewName")
        #expect(player.username == "NewName")
        #expect(player.coinBalance == 500)
    }

    @Test func invalidJSONBodyMapsToDecodingError() async throws {
        let client = makeClient { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }

        do {
            _ = try await client.fetchPlayers()
            Issue.record("Expected a decoding error to be thrown")
        } catch let error as APIError {
            guard case .decoding = error else {
                Issue.record("Expected .decoding, got \(error)")
                return
            }
        }
    }
}
