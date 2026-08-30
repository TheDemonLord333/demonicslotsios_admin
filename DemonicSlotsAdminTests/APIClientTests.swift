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

    @Test func fetchPlayerEncodesUsernameInRequestURL() async throws {
        let client = makeClient { request in
            #expect(request.url?.absoluteString.hasSuffix("/api/admin/players/john%20doe") == true)
            let json = #"{"username":"john doe","coinBalance":10,"adminRevision":1}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let player = try await client.fetchPlayer(username: "john doe")
        #expect(player.username == "john doe")
    }

    @Test func updateBalanceSendsPatchWithBalanceBody() async throws {
        let client = makeClient { request in
            #expect(request.httpMethod == "PATCH")
            #expect(request.url?.absoluteString.hasSuffix("/api/admin/players/Bob/balance") == true)
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Int]
            #expect(json?["balance"] == 2500)
            let responseJSON = #"{"username":"Bob","coinBalance":2500,"adminRevision":2}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let player = try await client.updateBalance(username: "Bob", balance: 2500)
        #expect(player.coinBalance == 2500)
        #expect(player.adminRevision == 2)
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
