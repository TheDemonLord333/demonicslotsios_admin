//
//  DemonicButton.swift
//  DemonicSlotsAdmin
//
//  Reusable primary/outline button with a built-in loading spinner and
//  disabled dimming, used for every submit action in the app.
//

import SwiftUI

enum DemonicButtonVariant {
    case primary
    case outline
}

struct DemonicButton: View {
    let title: String
    var variant: DemonicButtonVariant = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .background(background)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(variant == .outline ? DemonicPalette.borderSubtle : .clear, lineWidth: 1)
        )
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled && !isLoading) ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(.isButton)
    }

    private var background: some View {
        Group {
            switch variant {
            case .primary:
                LinearGradient(
                    colors: [DemonicPalette.glowingViolet, DemonicPalette.glowingViolet.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .outline:
                DemonicPalette.darkVioletElevated
            }
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: return .white
        case .outline: return DemonicPalette.boneIvory
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DemonicButton(title: "Verbinden", action: {})
        DemonicButton(title: "Lädt …", isLoading: true, action: {})
        DemonicButton(title: "Deaktiviert", isDisabled: true, action: {})
        DemonicButton(title: "Abbrechen", variant: .outline, action: {})
    }
    .padding()
    .background(DemonicPalette.obsidianBlack)
}
