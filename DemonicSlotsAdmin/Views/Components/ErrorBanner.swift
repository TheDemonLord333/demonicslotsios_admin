//
//  ErrorBanner.swift
//  DemonicSlotsAdmin
//

import SwiftUI

struct ErrorBanner: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(DemonicPalette.hellfireRed)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DemonicPalette.boneIvory)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let retryAction {
                Button("Erneut versuchen", action: retryAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DemonicPalette.emberOrange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DemonicPalette.hellfireRed.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DemonicPalette.hellfireRed.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message))
    }
}

#Preview {
    ZStack {
        DemonicPalette.obsidianBlack.ignoresSafeArea()
        ErrorBanner(message: "Netzwerkfehler – Server nicht erreichbar.", retryAction: {})
            .padding()
    }
}
