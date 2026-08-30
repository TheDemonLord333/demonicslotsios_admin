//
//  DemonicBackground.swift
//  DemonicSlotsAdmin
//
//  Reusable obsidian background with two very subtle radial glows.
//  Kept cheap and calm on purpose: no particle systems, no flashing,
//  and animation is skipped entirely when Reduce Motion is enabled.
//

import SwiftUI

struct DemonicBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            DemonicPalette.obsidianBlack

            RadialGradient(
                colors: [DemonicPalette.glowingViolet.opacity(0.26), .clear],
                center: UnitPoint(x: 0.22, y: 0.05),
                startRadius: 10,
                endRadius: animate ? 460 : 400
            )

            RadialGradient(
                colors: [DemonicPalette.emberOrange.opacity(0.14), .clear],
                center: UnitPoint(x: 0.82, y: 0.98),
                startRadius: 10,
                endRadius: animate ? 360 : 300
            )
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    DemonicBackground()
}
