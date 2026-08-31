//
//  APIClientErrorMappingTests.swift
//  DemonicSlotsAdminTests
//
//  HTTP status code -> APIError mapping for 401 / 404 / 409 / 500, and
//  the 400/409 validation error-code -> German message mapping.
//

import Testing
import Foundation
@testable import DemonicSlotsAdmin

@MainActor
struct APIClientErrorMappingTests {
    private func makeClient(status: Int, body: Data = Data()) -> APIClient {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
        return APIClient(
            baseURL: URL(string: "https://demonicslots.example.com")!,
            token: "test-token",
            session: MockSession.makeURLSession()
        )
    }

    @Test func status401MapsToUnauthorized() async throws {
        let client = makeClient(status: 401)
        do {
            _ = try await client.fetchPlayers()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            #expect(error == .unauthorized)
        }
    }

    @Test func status404MapsToPlayerNotFound() async throws {
        let client = makeClient(status: 404)
        do {
            _ = try await client.fetchPlayer(id: "ghost")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            #expect(error == .playerNotFound)
        }
    }

    @Test func status400WithInvalidUsernameMapsToFriendlyMessage() async throws {
        let body = #"{"error":"invalid_username"}"#.data(using: .utf8)!
        let client = makeClient(status: 400, body: body)
        do {
            _ = try await client.renameUsername(id: "player-1", newUsername: "!!")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            #expect(error == .validation(message: "Ungültiger Username (3–20 Zeichen: Buchstaben, Zahlen, „_“)."))
        }
    }

    @Test func status400WithInvalidBalanceMapsToFriendlyMessage() async throws {
        let body = #"{"error":"invalid_balance"}"#.data(using: .utf8)!
        let client = makeClient(status: 400, body: body)
        do {
            _ = try await client.updateBalance(id: "player-1", balance: -1)
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            #expect(error == .validation(message: "Ungültiges Guthaben."))
        }
    }

    @Test func status409WithUsernameTakenMapsToFriendlyMessage() async throws {
        let body = #"{"error":"username_taken"}"#.data(using: .utf8)!
        let client = makeClient(status: 409, body: body)
        do {
            _ = try await client.renameUsername(id: "player-1", newUsername: "Taken")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            #expect(error == .validation(message: "Dieser Username ist bereits vergeben."))
        }
    }

    @Test func status400WithUnknownCodeFallsBackToGenericMessage() async throws {
        let body = #"{"error":"something_else"}"#.data(using: .utf8)!
        let client = makeClient(status: 400, body: body)
        do {
            _ = try await client.fetchPlayers()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .validation(let message) = error else {
                Issue.record("Expected .validation, got \(error)")
                return
            }
            #expect(message.contains("something_else"))
        }
    }

    @Test func status500MapsToServerErrorWithMessage() async throws {
        let body = #"{"error":"ADMIN_TOKEN missing"}"#.data(using: .utf8)!
        let client = makeClient(status: 500, body: body)
        do {
            _ = try await client.fetchPlayers()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .serverError(let message) = error else {
                Issue.record("Expected .serverError, got \(error)")
                return
            }
            #expect(message == "ADMIN_TOKEN missing")
        }
    }

    @Test func status500WithoutBodyStillMapsToServerError() async throws {
        let client = makeClient(status: 500)
        do {
            _ = try await client.fetchPlayers()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .serverError = error else {
                Issue.record("Expected .serverError, got \(error)")
                return
            }
        }
    }

    @Test func unmappedStatusCodeMapsToUnknownStatus() async throws {
        let client = makeClient(status: 418)
        do {
            _ = try await client.fetchPlayers()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            #expect(error == .unknownStatus(418))
        }
    }
}
