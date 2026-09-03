//
//  AdminEndpointTests.swift
//  DemonicSlotsAdminTests
//
//  API path construction and id percent-encoding.
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct AdminEndpointTests {
    @Test func playersPath() {
        #expect(AdminEndpoint.players.path == "/api/admin/players")
    }

    @Test func playerPathForSimpleId() {
        #expect(AdminEndpoint.player(id: "abc-123").path == "/api/admin/players/abc-123")
    }

    @Test func updatePlayerSharesThePlayerResourcePath() {
        // The consolidated PATCH is the same resource as GET, only the
        // HTTP method differs — there's no separate /balance or /username
        // suffix anymore.
        #expect(AdminEndpoint.updatePlayer(id: "abc-123").path == "/api/admin/players/abc-123")
        #expect(AdminEndpoint.updatePlayer(id: "abc-123").path == AdminEndpoint.player(id: "abc-123").path)
    }

    @Test func playerPathEncodesSpaces() {
        #expect(AdminEndpoint.player(id: "some id").path == "/api/admin/players/some%20id")
    }

    @Test func playerPathEncodesSlash() {
        #expect(AdminEndpoint.player(id: "a/b").path == "/api/admin/players/a%2Fb")
    }

    @Test func playerPathEncodesSpecialCharacters() {
        #expect(AdminEndpoint.player(id: "id+name@test&x=1").path == "/api/admin/players/id%2Bname%40test%26x%3D1")
    }

    @Test func playerPathPreservesUnreservedCharacters() {
        #expect(AdminEndpoint.player(id: "abc-DEF_123.~").path == "/api/admin/players/abc-DEF_123.~")
    }

    @Test func httpMethods() {
        #expect(AdminEndpoint.players.httpMethod == "GET")
        #expect(AdminEndpoint.player(id: "x").httpMethod == "GET")
        #expect(AdminEndpoint.updatePlayer(id: "x").httpMethod == "PATCH")
    }
}
