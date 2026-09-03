//
//  PlayerUpdateFields.swift
//  DemonicSlotsAdmin
//
//  Body for the consolidated `PATCH /api/admin/players/:id`: any
//  non-empty subset of these fields. Every property is Optional, and
//  Swift's synthesized Encodable calls `encodeIfPresent` for Optional
//  properties, so a `nil` field is simply omitted from the JSON rather
//  than encoded as `null` — exactly the "only send what changed" shape
//  the backend expects (mirrors demonicslotsweb_admin's `fields` object).
//

import Foundation

struct PlayerUpdateFields: Encodable, Equatable {
    var username: String?
    var balance: Int?
    var level: Int?
    var winChanceMultiplier: Double?
    var guaranteedJackpot: Bool?

    var isEmpty: Bool {
        username == nil && balance == nil && level == nil && winChanceMultiplier == nil && guaranteedJackpot == nil
    }
}
