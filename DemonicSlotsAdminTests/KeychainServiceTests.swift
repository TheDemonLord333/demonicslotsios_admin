//
//  KeychainServiceTests.swift
//  DemonicSlotsAdminTests
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct KeychainServiceTests {
    @Test func savesLoadsAndDeletesToken() throws {
        let keychain = KeychainService()
        try? keychain.deleteToken()

        try keychain.save(token: "unit-test-token-123")
        #expect(try keychain.loadToken() == "unit-test-token-123")

        try keychain.deleteToken()
        #expect(try keychain.loadToken() == nil)
    }

    @Test func savingTwiceOverwritesPreviousToken() throws {
        let keychain = KeychainService()
        try? keychain.deleteToken()

        try keychain.save(token: "first-token")
        try keychain.save(token: "second-token")
        #expect(try keychain.loadToken() == "second-token")

        try? keychain.deleteToken()
    }
}
