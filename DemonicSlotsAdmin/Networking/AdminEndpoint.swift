//
//  AdminEndpoint.swift
//  DemonicSlotsAdmin
//
//  Builds the `/api/admin/...` paths used by APIClient. Kept as a pure,
//  network-free type so path construction and id percent-encoding are
//  independently unit-testable.
//

import Foundation

enum AdminEndpoint: Equatable {
    case players
    case player(id: String)
    case updateBalance(id: String)
    case renameUsername(id: String)

    var path: String {
        switch self {
        case .players:
            return "/api/admin/players"
        case .player(let id):
            return "/api/admin/players/\(PathEncoding.encodeComponent(id))"
        case .updateBalance(let id):
            return "/api/admin/players/\(PathEncoding.encodeComponent(id))/balance"
        case .renameUsername(let id):
            return "/api/admin/players/\(PathEncoding.encodeComponent(id))/username"
        }
    }

    var httpMethod: String {
        switch self {
        case .players, .player:
            return "GET"
        case .updateBalance, .renameUsername:
            return "PATCH"
        }
    }
}

/// Percent-encodes a single path component the same way JavaScript's
/// `encodeURIComponent` does, so ids/usernames containing spaces, slashes,
/// `@`, `+`, `&`, `=`, etc. are always safely embedded in the URL path.
enum PathEncoding {
    private static let unreservedCharacters: CharacterSet = {
        var allowed = CharacterSet(charactersIn: "-_.!~*'()")
        allowed.formUnion(.alphanumerics)
        return allowed
    }()

    static func encodeComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? value
    }
}
