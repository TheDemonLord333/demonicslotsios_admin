//
//  Player.swift
//  DemonicSlotsAdmin
//
//  Codable model for a Demonic Slots player, as returned by
//  GET /api/admin/players and /api/admin/players/:username.
//

import Foundation

struct Player: Codable, Identifiable, Equatable, Hashable {
    let username: String
    let coinBalance: Int
    /// Raw ISO-8601 string as received from the server, kept around so a
    /// malformed-but-present date can still be shown instead of silently
    /// disappearing. Use `createdAt` for the parsed `Date`.
    let createdAtRaw: String?
    let updatedAtRaw: String?
    let adminRevision: Int?

    var id: String { username }

    var createdAt: Date? { DemonicDateParser.parse(createdAtRaw) }
    var updatedAt: Date? { DemonicDateParser.parse(updatedAtRaw) }

    private enum CodingKeys: String, CodingKey {
        case username
        case coinBalance
        case createdAtRaw = "createdAt"
        case updatedAtRaw = "updatedAt"
        case adminRevision
    }

    init(
        username: String,
        coinBalance: Int,
        createdAtRaw: String? = nil,
        updatedAtRaw: String? = nil,
        adminRevision: Int? = nil
    ) {
        self.username = username
        self.coinBalance = coinBalance
        self.createdAtRaw = createdAtRaw
        self.updatedAtRaw = updatedAtRaw
        self.adminRevision = adminRevision
    }

    /// Custom decoding so that missing *or malformed* optional metadata
    /// (createdAt/updatedAt/adminRevision) never causes the whole player —
    /// or the whole players list — to fail to decode. Only `username` and
    /// `coinBalance` are required.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        coinBalance = try container.decode(Int.self, forKey: .coinBalance)
        createdAtRaw = try? container.decodeIfPresent(String.self, forKey: .createdAtRaw)
        updatedAtRaw = try? container.decodeIfPresent(String.self, forKey: .updatedAtRaw)
        adminRevision = try? container.decodeIfPresent(Int.self, forKey: .adminRevision)
    }
}
