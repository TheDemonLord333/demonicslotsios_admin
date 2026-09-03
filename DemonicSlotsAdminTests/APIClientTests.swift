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

    private static let fullPlayerJSON = """
    {"id":"p-1","username":"john","coinBalance":10,"level":5,"winChanceMultiplier":1.25,"guaranteedJackpot":false,"adminRevision":1}
    """

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
            let json = #"{"id":"id with space","username":"john","coinBalance":10,"level":1,"winChanceMultiplier":1.0,"guaranteedJackpot":false,"adminRevision":1}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let player = try await client.fetchPlayer(id: "id with space")
        #expect(player.username == "john")
        #expect(player.id == "id with space")
    }

    @Test func updatePlayerSendsPatchToPlayerResource() async throws {
        let client = makeClient { request in
            #expect(request.httpMethod == "PATCH")
            #expect(request.url?.absoluteString.hasSuffix("/api/admin/players/player-1") == true)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.fullPlayerJSON.data(using: .utf8)!)
        }

        let fields = PlayerUpdateFields(balance: 2500)
        let player = try await client.updatePlayer(id: "player-1", fields: fields)
        #expect(player.id == "p-1")
    }

    @Test func updatePlayerBodyOnlyIncludesFieldsThatWereSet() async throws {
        let client = makeClient { request in
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            // Only `balance` was set on the fields struct — username, level,
            // winChanceMultiplier, and guaranteedJackpot must be entirely
            // absent from the encoded body, not present as `null`.
            #expect(json?.count == 1)
            #expect(json?["balance"] as? Int == 2500)
            #expect(json?["username"] == nil)
            #expect(json?["level"] == nil)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.fullPlayerJSON.data(using: .utf8)!)
        }

        _ = try await client.updatePlayer(id: "player-1", fields: PlayerUpdateFields(balance: 2500))
    }

    @Test func updatePlayerBodyIncludesAllProvidedFields() async throws {
        let client = makeClient { request in
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            #expect(json?["username"] as? String == "NewName")
            #expect(json?["balance"] as? Int == 500)
            #expect(json?["level"] as? Int == 10)
            #expect((json?["winChanceMultiplier"] as? NSNumber)?.doubleValue == 1.5)
            #expect(json?["guaranteedJackpot"] as? Bool == true)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.fullPlayerJSON.data(using: .utf8)!)
        }

        let fields = PlayerUpdateFields(
            username: "NewName",
            balance: 500,
            level: 10,
            winChanceMultiplier: 1.5,
            guaranteedJackpot: true
        )
        _ = try await client.updatePlayer(id: "player-1", fields: fields)
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
