//
//  PlayerRowView.swift
//  DemonicSlotsAdmin
//

import SwiftUI

struct PlayerRowView: View {
    let player: Player

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.username)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(DemonicPalette.boneIvory)
                    .lineLimit(1)

                Text("Aktualisiert: \(DemonicFormatters.formatDate(player.updatedAt, fallbackRaw: player.updatedAtRaw))")
                    .font(.caption)
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(DemonicFormatters.formatCoins(player.coinBalance))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(DemonicPalette.emberOrange)
                    .shadow(color: DemonicPalette.emberOrange.opacity(0.4), radius: 6)
                    .contentTransition(.numericText())
                Text("Coins")
                    .font(.caption2)
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.5))
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.3))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.username), \(DemonicFormatters.formatCoins(player.coinBalance)) Coins, zuletzt aktualisiert \(DemonicFormatters.formatDate(player.updatedAt, fallbackRaw: player.updatedAtRaw))"
        )
    }
}

#Preview {
    List {
        PlayerRowView(player: Player(username: "DemonSlayer99", coinBalance: 128_500, updatedAtRaw: "2026-08-20T10:00:00Z", adminRevision: 4))
    }
    .listStyle(.plain)
    .background(DemonicPalette.obsidianBlack)
}
