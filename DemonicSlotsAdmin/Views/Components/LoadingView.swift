//
//  LoadingView.swift
//  DemonicSlotsAdmin
//

import SwiftUI

struct LoadingView: View {
    var message: String = "Lädt …"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DemonicPalette.emberOrange)
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        DemonicPalette.obsidianBlack.ignoresSafeArea()
        LoadingView()
    }
}
