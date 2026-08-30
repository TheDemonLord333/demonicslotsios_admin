//
//  KeychainService.swift
//  DemonicSlotsAdmin
//
//  Stores the admin bearer token in the iOS Keychain — never in
//  UserDefaults, never in source code, never logged.
//

import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case unexpectedStatus(OSStatus)
    case unexpectedData

    var errorDescription: String? {
        "Der Token konnte nicht sicher gespeichert werden."
    }
}

protocol KeychainServicing {
    func save(token: String) throws
    func loadToken() throws -> String?
    func deleteToken() throws
}

@MainActor
final class KeychainService: KeychainServicing {
    private let service = "me.thedemonlord333.DemonicSlotsAdmin.adminToken"
    private let account = "admin-token"

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    func save(token: String) throws {
        // Remove any existing item first so re-login always overwrites cleanly.
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = Data(token.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func loadToken() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return token
    }

    func deleteToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
