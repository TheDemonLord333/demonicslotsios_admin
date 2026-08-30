//
//  DemonicPalette.swift
//  DemonicSlotsAdmin
//
//  Central color definitions matching the demonicslotsweb_admin theme
//  (see css/styles.css custom properties in the reference web app).
//

import SwiftUI

/// The demonic color palette shared by every screen in the app.
enum DemonicPalette {
    static let obsidianBlack = Color(red: 8 / 255, green: 7 / 255, blue: 11 / 255)
    static let darkViolet = Color(red: 25 / 255, green: 14 / 255, blue: 36 / 255)
    static let darkVioletElevated = Color(red: 34 / 255, green: 18 / 255, blue: 49 / 255)
    static let hellfireRed = Color(red: 226 / 255, green: 45 / 255, blue: 61 / 255)
    static let glowingViolet = Color(red: 110 / 255, green: 67 / 255, blue: 255 / 255)
    static let emberOrange = Color(red: 255 / 255, green: 122 / 255, blue: 26 / 255)
    static let boneIvory = Color(red: 232 / 255, green: 222 / 255, blue: 201 / 255)

    /// Thin, semi-transparent light border used on cards and fields.
    static let borderSubtle = boneIvory.opacity(0.12)
}
