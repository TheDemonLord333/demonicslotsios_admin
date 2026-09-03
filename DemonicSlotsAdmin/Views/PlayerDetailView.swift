//
//  PlayerDetailView.swift
//  DemonicSlotsAdmin
//

import SwiftUI
import UIKit

struct PlayerDetailView: View {
    @StateObject private var viewModel: PlayerDetailViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, balance
    }

    init(
        player: Player,
        client: AdminAPIClientProtocol,
        onUnauthorized: @escaping () -> Void,
        onUpdated: @escaping (Player) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            player: player,
            client: client,
            onUnauthorized: onUnauthorized,
            onUpdated: onUpdated
        ))
    }

    var body: some View {
        ZStack {
            DemonicPalette.obsidianBlack.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    editCard
                    if let successMessage = viewModel.successMessage {
                        SuccessBanner(message: successMessage)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(viewModel.player.username)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            confirmationTitle,
            isPresented: confirmationBinding,
            titleVisibility: .visible
        ) {
            // Captured here (while the dialog is actually presented) so the
            // button's action below doesn't depend on `pendingConfirmation`
            // still being set once its Task actually runs — SwiftUI clears
            // it via `confirmationBinding`'s `set` as soon as any dialog
            // button is tapped, which can otherwise race ahead of the save.
            if let pending = viewModel.pendingConfirmation {
                Button("Ändern") {
                    Task {
                        let success = await viewModel.confirmSave(pending)
                        if success {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                }
            }
            Button("Abbrechen", role: .cancel) {
                viewModel.cancelConfirmation()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.successMessage)
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingConfirmation != nil },
            set: { isPresented in
                if !isPresented { viewModel.cancelConfirmation() }
            }
        )
    }

    /// Describes whichever field(s) actually changed — any combination of
    /// username, balance, level, multiplier, and jackpot — as one natural
    /// German sentence.
    private var confirmationTitle: String {
        guard let pending = viewModel.pendingConfirmation else { return "" }

        var parts: [String] = []
        if let newUsername = pending.newUsername {
            parts.append("den Username von „\(viewModel.player.username)“ zu „\(newUsername)“")
        }
        if let newBalance = pending.newBalance {
            parts.append(
                "das Guthaben von \(DemonicFormatters.formatCoins(viewModel.player.coinBalance)) "
                    + "auf \(DemonicFormatters.formatCoins(newBalance)) Coins"
            )
        }
        if let newLevel = pending.newLevel {
            parts.append("das Level von \(viewModel.player.level) auf \(newLevel)")
        }
        if let newMultiplier = pending.newMultiplier {
            parts.append(
                "den Multiplikator von \(DemonicFormatters.formatMultiplier(viewModel.player.winChanceMultiplier))× "
                    + "auf \(DemonicFormatters.formatMultiplier(newMultiplier))×"
            )
        }
        if let newJackpot = pending.newGuaranteedJackpot {
            parts.append(newJackpot ? "den garantierten Jackpot zu aktivieren" : "den garantierten Jackpot zu deaktivieren")
        }

        let joined: String
        if let last = parts.last, parts.count > 1 {
            joined = parts.dropLast().joined(separator: ", ") + " und " + last
        } else {
            joined = parts.first ?? ""
        }
        return "Möchtest du \(joined) wirklich ändern?"
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Aktuelles Guthaben")
                    .font(.caption)
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.6))
                Text("\(DemonicFormatters.formatCoins(viewModel.player.coinBalance)) Coins")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(DemonicPalette.emberOrange)
                    .shadow(color: DemonicPalette.emberOrange.opacity(0.4), radius: 8)
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: viewModel.player.coinBalance)
            }

            Divider().background(DemonicPalette.borderSubtle)

            infoRow(label: "Level", value: "\(viewModel.player.level)")
            infoRow(label: "Multiplikator", value: "\(DemonicFormatters.formatMultiplier(viewModel.player.winChanceMultiplier))×")
            infoRow(label: "Garantierter Jackpot", value: viewModel.player.guaranteedJackpot ? "🔥 Aktiv" : "Aus")
            infoRow(label: "Erstellt", value: DemonicFormatters.formatDate(viewModel.player.createdAt, fallbackRaw: viewModel.player.createdAtRaw))
            infoRow(label: "Zuletzt aktualisiert", value: DemonicFormatters.formatDate(viewModel.player.updatedAt, fallbackRaw: viewModel.player.updatedAtRaw))
            infoRow(label: "Admin-Revision", value: viewModel.player.adminRevision.map { "#\($0)" } ?? "—")
        }
        .demonicCard()
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DemonicPalette.boneIvory)
        }
        .accessibilityElement(children: .combine)
    }

    private var editCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            usernameField
            balanceField
            levelField
            multiplierField
            jackpotToggleRow

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
            }

            DemonicButton(
                title: "Speichern",
                isLoading: viewModel.isSaving,
                isDisabled: !viewModel.canSubmit
            ) {
                focusedField = nil
                viewModel.requestConfirmation()
            }
        }
        .demonicCard()
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
            TextField("Username", text: $viewModel.usernameInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .balance }
                .demonicField(isFocused: focusedField == .username)
                .accessibilityLabel("Username")
            Text("3–20 Zeichen: Buchstaben, Zahlen, „_“.")
                .font(.caption2)
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.5))
        }
    }

    private var balanceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Neues Guthaben")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
            TextField("Guthaben", text: $viewModel.balanceInput)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .balance)
                .demonicField(isFocused: focusedField == .balance)
                .accessibilityLabel("Neues Guthaben in Coins")
                .onChange(of: viewModel.balanceInput) { _, newValue in
                    let filtered = newValue.filter { $0.isASCII && $0.isNumber }
                    if filtered != newValue {
                        viewModel.balanceInput = filtered
                    }
                }
        }
    }

    private var levelField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Level")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
            Stepper(value: $viewModel.levelValue, in: LevelValidator.range) {
                Text("\(viewModel.levelValue)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(DemonicPalette.boneIvory)
            }
            .demonicStepperChrome()
            .accessibilityLabel("Level")
            .accessibilityValue("\(viewModel.levelValue)")
        }
    }

    private var multiplierField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wahrscheinlichkeits-Multiplikator")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
            Stepper(value: $viewModel.multiplierValue, in: WinChanceMultiplierValidator.range, step: 0.05) {
                Text("\(DemonicFormatters.formatMultiplier(viewModel.multiplierValue))×")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(DemonicPalette.boneIvory)
            }
            .demonicStepperChrome()
            .accessibilityLabel("Wahrscheinlichkeits-Multiplikator")
            .accessibilityValue(DemonicFormatters.formatMultiplier(viewModel.multiplierValue))
            Text("0,10–2,00× · 1,00× = neutral")
                .font(.caption2)
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.5))
        }
    }

    private var jackpotToggleRow: some View {
        Toggle(isOn: $viewModel.jackpotEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Garantierter Jackpot")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DemonicPalette.boneIvory)
                Text("Gewinnt ab dem nächsten Sync garantiert jeden Spin.")
                    .font(.caption2)
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.55))
            }
        }
        .tint(DemonicPalette.emberOrange)
        .accessibilityLabel("Garantierter Jackpot")
    }
}
