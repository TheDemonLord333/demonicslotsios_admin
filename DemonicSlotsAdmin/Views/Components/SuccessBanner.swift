//
//  SuccessBanner.swift
//  DemonicSlotsAdmin
//

import SwiftUI

struct SuccessBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DemonicPalette.glowingViolet)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DemonicPalette.boneIvory)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DemonicPalette.glowingViolet.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DemonicPalette.glowingViolet.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct EmptyStateView: View {
    let text: String
    var systemImage: String = "person.crop.circle.badge.questionmark"

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.35))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
