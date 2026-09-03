//
//  DemonicComponents.swift
//  DemonicSlotsAdmin
//
//  Shared ViewModifiers so cards, fields, and headings look consistent
//  across Login, Dashboard, Detail, and Settings without duplicating
//  styling code in every view.
//

import SwiftUI

// MARK: - Card

private struct DemonicCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(DemonicPalette.darkViolet)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(DemonicPalette.borderSubtle, lineWidth: 1)
            )
    }
}

extension View {
    /// Applies the standard dark-violet, subtly-bordered card background.
    func demonicCard() -> some View {
        modifier(DemonicCardStyle())
    }
}

// MARK: - Heading

private struct DemonicHeadingStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title2, design: .rounded, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(DemonicPalette.boneIvory)
    }
}

extension View {
    /// Kantige, leicht gespreizte Überschrift – nur für Titel, nicht für Fließtext.
    func demonicHeading() -> some View {
        modifier(DemonicHeadingStyle())
    }
}

// MARK: - Text field background

private struct DemonicFieldBackground: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundStyle(DemonicPalette.boneIvory)
            .tint(DemonicPalette.glowingViolet)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DemonicPalette.darkVioletElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isFocused ? DemonicPalette.glowingViolet.opacity(0.8) : DemonicPalette.borderSubtle,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(color: isFocused ? DemonicPalette.glowingViolet.opacity(0.35) : .clear, radius: 8)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

extension View {
    /// Standard demonic text field chrome. Pass `isFocused` for a soft violet glow on focus.
    func demonicField(isFocused: Bool = false) -> some View {
        modifier(DemonicFieldBackground(isFocused: isFocused))
    }
}

// MARK: - Stepper chrome

private struct DemonicStepperChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .tint(DemonicPalette.glowingViolet)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DemonicPalette.darkVioletElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DemonicPalette.borderSubtle, lineWidth: 1)
            )
    }
}

extension View {
    /// Same background/border as `demonicField`, sized for a `Stepper`.
    func demonicStepperChrome() -> some View {
        modifier(DemonicStepperChrome())
    }
}
