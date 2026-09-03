//
//  Player.swift
//  DemonicSlotsAdmin
//
//  Codable model for a Demonic Slots player, as returned by
//  GET /api/admin/players and /api/admin/players/:id.
//
//  `id` is the stable, immutable identifier the backend assigns to every
//  player; `username` is just a mutable label on top of it and can be
//  renamed. All per-player requests must address a player by `id`, never
//  by `username`.
//

import Foundation

struct Player: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let username: String
    let coinBalance: Int
    /// 1–100.
    let level: Int
    /// 0.10–2.00 (1.0 = neutral); additionally scales a player's in-game
    /// win chance on top of their level bonus.
    let winChanceMultiplier: Double
    /// When true, the player's device guarantees a win on every spin/climb
    /// attempt from the next sync onward (no app update required).
    let guaranteedJackpot: Bool
    /// Raw ISO-8601 string as received from the server, kept around so a
    /// malformed-but-present date can still be shown instead of silently
    /// disappearing. Use `createdAt` for the parsed `Date`.
    let createdAtRaw: String?
    let updatedAtRaw: String?
    let adminRevision: Int?

    var createdAt: Date? { DemonicDateParser.parse(createdAtRaw) }
    var updatedAt: Date? { DemonicDateParser.parse(updatedAtRaw) }

    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case coinBalance
        case level
        case winChanceMultiplier
        case guaranteedJackpot
        case createdAtRaw = "createdAt"
        case updatedAtRaw = "updatedAt"
        case adminRevision
    }

    init(
        id: String = UUID().uuidString,
        username: String,
        coinBalance: Int,
        level: Int = 1,
        winChanceMultiplier: Double = 1.0,
        guaranteedJackpot: Bool = false,
        createdAtRaw: String? = nil,
        updatedAtRaw: String? = nil,
        adminRevision: Int? = nil
    ) {
        self.id = id
        self.username = username
        self.coinBalance = coinBalance
        self.level = level
        self.winChanceMultiplier = winChanceMultiplier
        self.guaranteedJackpot = guaranteedJackpot
        self.createdAtRaw = createdAtRaw
        self.updatedAtRaw = updatedAtRaw
        self.adminRevision = adminRevision
    }

    /// Custom decoding so that missing *or malformed* optional metadata
    /// (createdAt/updatedAt/adminRevision) never causes the whole player —
    /// or the whole players list — to fail to decode. Everything else is
    /// required: a player without a stable `id` can't be addressed for
    /// updates at all, and level/multiplier/jackpot are always present on
    /// the current backend contract.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        coinBalance = try container.decode(Int.self, forKey: .coinBalance)
        level = try container.decode(Int.self, forKey: .level)
        winChanceMultiplier = try container.decode(Double.self, forKey: .winChanceMultiplier)
        guaranteedJackpot = try container.decode(Bool.self, forKey: .guaranteedJackpot)
        createdAtRaw = try? container.decodeIfPresent(String.self, forKey: .createdAtRaw)
        updatedAtRaw = try? container.decodeIfPresent(String.self, forKey: .updatedAtRaw)
        adminRevision = try? container.decodeIfPresent(Int.self, forKey: .adminRevision)
    }
}
