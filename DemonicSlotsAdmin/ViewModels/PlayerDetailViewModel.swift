//
//  PlayerDetailViewModel.swift
//  DemonicSlotsAdmin
//

import Combine
import Foundation

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    struct PendingChange: Identifiable {
        let id = UUID()
        let newBalance: Int
    }

    @Published private(set) var player: Player
    @Published var balanceInput: String
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published private(set) var pendingConfirmation: PendingChange?

    private let client: AdminAPIClientProtocol
    private let onUnauthorized: () -> Void
    private let onUpdated: (Player) -> Void

    init(
        player: Player,
        client: AdminAPIClientProtocol,
        onUnauthorized: @escaping () -> Void,
        onUpdated: @escaping (Player) -> Void
    ) {
        self.player = player
        self.balanceInput = String(player.coinBalance)
        self.client = client
        self.onUnauthorized = onUnauthorized
        self.onUpdated = onUpdated
    }

    var validatedBalance: Int? {
        BalanceValidator.validate(balanceInput)
    }

    var canSubmit: Bool {
        validatedBalance != nil && !isSaving
    }

    /// Step 1: validate, then surface a native confirmation dialog before
    /// actually sending the PATCH request.
    func requestConfirmation() {
        errorMessage = nil
        successMessage = nil
        guard let value = validatedBalance else {
            errorMessage = "Bitte eine gültige, nicht-negative ganze Zahl eingeben."
            return
        }
        pendingConfirmation = PendingChange(newBalance: value)
    }

    func cancelConfirmation() {
        pendingConfirmation = nil
    }

    /// Step 2: user tapped "Ändern" in the confirmation dialog. `pending`
    /// is passed in explicitly (captured by the caller at the moment the
    /// dialog's actions were built) rather than re-read from
    /// `pendingConfirmation` here: SwiftUI clears `isPresented` — and thus
    /// `pendingConfirmation`, via `cancelConfirmation()` — as soon as any
    /// dialog button is tapped, which can race ahead of this `async` call
    /// and would otherwise find it already `nil`. Returns `true` on
    /// success so the caller can trigger haptic feedback.
    @discardableResult
    func confirmSave(_ pending: PendingChange) async -> Bool {
        pendingConfirmation = nil
        return await save(newBalance: pending.newBalance)
    }

    private func save(newBalance: Int) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            let updated = try await client.updateBalance(username: player.username, balance: newBalance)
            player = updated
            balanceInput = String(updated.coinBalance)
            successMessage = "Guthaben von „\(updated.username)“ auf \(DemonicFormatters.formatCoins(updated.coinBalance)) Coins gesetzt."
            onUpdated(updated)
            return true
        } catch let error as APIError {
            if error == .unauthorized {
                onUnauthorized()
            } else {
                // Keep the previous player data — only surface the error.
                errorMessage = error.errorDescription
            }
            return false
        } catch {
            errorMessage = "Unbekannter Fehler."
            return false
        }
    }
}
