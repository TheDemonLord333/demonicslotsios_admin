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
    /// Same resource as `.player(id:)` — the backend consolidated balance/
    /// username/level/multiplier/jackpot updates into one
    /// `PATCH /api/admin/players/:id`, so only the HTTP method differs.
    case updatePlayer(id: String)

    var path: String {
        switch self {
        case .players:
            return "/api/admin/players"
        case .player(let id), .updatePlayer(let id):
            return "/api/admin/players/\(PathEncoding.encodeComponent(id))"
        }
    }

    var httpMethod: String {
        switch self {
        case .players, .player:
            return "GET"
        case .updatePlayer:
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
