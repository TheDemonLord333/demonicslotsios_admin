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

                HStack(spacing: 6) {
                    badge("Lvl \(player.level)")
                    badge("\(DemonicFormatters.formatMultiplier(player.winChanceMultiplier))×")
                    if player.guaranteedJackpot {
                        jackpotBadge
                    }
                }

                Text("Aktualisiert: \(DemonicFormatters.formatDate(player.updatedAt, fallbackRaw: player.updatedAtRaw))")
                    .font(.caption2)
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.45))
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
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        var text = "\(player.username), \(DemonicFormatters.formatCoins(player.coinBalance)) Coins, "
            + "Level \(player.level), Multiplikator \(DemonicFormatters.formatMultiplier(player.winChanceMultiplier))"
        if player.guaranteedJackpot {
            text += ", garantierter Jackpot aktiv"
        }
        text += ", zuletzt aktualisiert \(DemonicFormatters.formatDate(player.updatedAt, fallbackRaw: player.updatedAtRaw))"
        return text
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(DemonicPalette.boneIvory.opacity(0.75))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(DemonicPalette.darkVioletElevated))
    }

    private var jackpotBadge: some View {
        Text("🔥 Jackpot")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(DemonicPalette.emberOrange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(DemonicPalette.emberOrange.opacity(0.15)))
            .overlay(Capsule().stroke(DemonicPalette.emberOrange.opacity(0.4), lineWidth: 1))
    }
}

#Preview {
    List {
        PlayerRowView(player: Player(
            username: "DemonSlayer99",
            coinBalance: 128_500,
            level: 42,
            winChanceMultiplier: 1.25,
            guaranteedJackpot: true,
            updatedAtRaw: "2026-08-20T10:00:00Z",
            adminRevision: 4
        ))
    }
    .listStyle(.plain)
    .background(DemonicPalette.obsidianBlack)
}
