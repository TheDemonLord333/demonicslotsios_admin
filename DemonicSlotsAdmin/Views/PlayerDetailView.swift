//
//  PlayerDetailView.swift
//  DemonicSlotsAdmin
//

import SwiftUI
import UIKit

struct PlayerDetailView: View {
    @StateObject private var viewModel: PlayerDetailViewModel
    @FocusState private var balanceFieldFocused: Bool

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
            Button("Ändern") {
                Task {
                    let success = await viewModel.confirmSave()
                    if success {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
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

    private var confirmationTitle: String {
        guard let pending = viewModel.pendingConfirmation else { return "" }
        return "Möchtest du das Guthaben von „\(viewModel.player.username)“ wirklich von "
            + "\(DemonicFormatters.formatCoins(viewModel.player.coinBalance)) auf "
            + "\(DemonicFormatters.formatCoins(pending.newBalance)) Coins ändern?"
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
            Text("Neues Guthaben")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))

            TextField("Guthaben", text: $viewModel.balanceInput)
                .keyboardType(.numberPad)
                .focused($balanceFieldFocused)
                .demonicField(isFocused: balanceFieldFocused)
                .accessibilityLabel("Neues Guthaben in Coins")
                .onChange(of: viewModel.balanceInput) { _, newValue in
                    let filtered = newValue.filter { $0.isASCII && $0.isNumber }
                    if filtered != newValue {
                        viewModel.balanceInput = filtered
                    }
                }

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
            }

            DemonicButton(
                title: "Guthaben speichern",
                isLoading: viewModel.isSaving,
                isDisabled: !viewModel.canSubmit
            ) {
                balanceFieldFocused = false
                viewModel.requestConfirmation()
            }
        }
        .demonicCard()
    }
}
