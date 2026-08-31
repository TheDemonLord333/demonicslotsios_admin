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

    /// Describes whichever field(s) actually changed — username, balance,
    /// or both — in one natural German sentence.
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
        return "Möchtest du \(parts.joined(separator: " und ")) wirklich ändern?"
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
        VStack(alignment: .leading, spacing: 14) {
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
}
