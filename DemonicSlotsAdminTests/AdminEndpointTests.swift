//
//  AdminEndpointTests.swift
//  DemonicSlotsAdminTests
//
//  API path construction and username percent-encoding.
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct AdminEndpointTests {
    @Test func playersPath() {
        #expect(AdminEndpoint.players.path == "/api/admin/players")
    }

    @Test func playerPathForSimpleUsername() {
        #expect(AdminEndpoint.player(username: "Bob").path == "/api/admin/players/Bob")
    }

    @Test func updateBalancePathAppendsBalanceSuffix() {
        #expect(AdminEndpoint.updateBalance(username: "Bob").path == "/api/admin/players/Bob/balance")
    }

    @Test func playerPathEncodesSpaces() {
        #expect(AdminEndpoint.player(username: "john doe").path == "/api/admin/players/john%20doe")
    }

    @Test func playerPathEncodesSlash() {
        #expect(AdminEndpoint.player(username: "a/b").path == "/api/admin/players/a%2Fb")
    }

    @Test func playerPathEncodesSpecialCharacters() {
        #expect(AdminEndpoint.player(username: "user+name@test&x=1").path == "/api/admin/players/user%2Bname%40test%26x%3D1")
    }

    @Test func playerPathPreservesUnreservedCharacters() {
        #expect(AdminEndpoint.player(username: "abc-DEF_123.~").path == "/api/admin/players/abc-DEF_123.~")
    }

    @Test func httpMethods() {
        #expect(AdminEndpoint.players.httpMethod == "GET")
        #expect(AdminEndpoint.player(username: "x").httpMethod == "GET")
        #expect(AdminEndpoint.updateBalance(username: "x").httpMethod == "PATCH")
    }
}
