//
//  APIClientErrorMappingTests.swift
//  DemonicSlotsAdminTests
//
//  HTTP status code -> APIError mapping for 401 / 404 / 500.
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
            _ = try await client.fetchPlayer(username: "ghost")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            #expect(error == .playerNotFound)
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
