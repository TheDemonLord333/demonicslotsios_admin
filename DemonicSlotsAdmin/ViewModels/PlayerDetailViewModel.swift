//
//  PlayerDetailViewModel.swift
//  DemonicSlotsAdmin
//
//  Username and balance are edited together in one form but saved as
//  independent PATCH requests (per demonicslotsweb_admin's behavior):
//  only the endpoints for fields that actually changed are called.
//

import Combine
import Foundation

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    struct PendingChange: Identifiable {
        let id = UUID()
        let newUsername: String?
        let newBalance: Int?
    }

    @Published private(set) var player: Player
    @Published var usernameInput: String
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
        self.usernameInput = player.username
        self.balanceInput = String(player.coinBalance)
        self.client = client
        self.onUnauthorized = onUnauthorized
        self.onUpdated = onUpdated
    }

    var validatedUsername: String? {
        UsernameValidator.validate(usernameInput)
    }

    var validatedBalance: Int? {
        BalanceValidator.validate(balanceInput)
    }

    private var usernameDidChange: Bool {
        guard let validatedUsername else { return false }
        return validatedUsername != player.username
    }

    private var balanceDidChange: Bool {
        guard let validatedBalance else { return false }
        return validatedBalance != player.coinBalance
    }

    /// Both fields must currently be valid (even the untouched one) and at
    /// least one of them must actually differ from the saved player.
    var canSubmit: Bool {
        guard !isSaving, validatedUsername != nil, validatedBalance != nil else { return false }
        return usernameDidChange || balanceDidChange
    }

    /// Step 1: validate, then surface a native confirmation dialog before
    /// actually sending any request. Only the fields that changed end up
    /// in `PendingChange` — an unchanged, still-valid field is left out.
    func requestConfirmation() {
        errorMessage = nil
        successMessage = nil

        guard let validatedUsername, let validatedBalance else {
            errorMessage = "Bitte einen gültigen Username (3–20 Zeichen: Buchstaben, Zahlen, „_“) und ein gültiges, nicht-negatives Guthaben angeben."
            return
        }

        let newUsername = validatedUsername != player.username ? validatedUsername : nil
        let newBalance = validatedBalance != player.coinBalance ? validatedBalance : nil
        guard newUsername != nil || newBalance != nil else { return }

        pendingConfirmation = PendingChange(newUsername: newUsername, newBalance: newBalance)
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
    /// and would otherwise find it already `nil`. Returns `true` on full
    /// success so the caller can trigger haptic feedback.
    @discardableResult
    func confirmSave(_ pending: PendingChange) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        pendingConfirmation = nil
        defer { isSaving = false }

        // Only the endpoints for fields that actually changed are called,
        // and each successfully-applied step is kept even if a later one
        // fails — so a rename that succeeds isn't silently reverted just
        // because the balance PATCH afterwards failed.
        var latest = player
        do {
            if let newUsername = pending.newUsername {
                latest = try await client.renameUsername(id: latest.id, newUsername: newUsername)
                apply(latest)
            }
            if let newBalance = pending.newBalance {
                latest = try await client.updateBalance(id: latest.id, balance: newBalance)
                apply(latest)
            }
            successMessage = Self.successMessage(for: pending, updated: latest)
            onUpdated(latest)
            return true
        } catch let error as APIError {
            if error == .unauthorized {
                onUnauthorized()
            } else {
                errorMessage = error.errorDescription
                onUpdated(latest)
            }
            return false
        } catch {
            errorMessage = "Unbekannter Fehler."
            onUpdated(latest)
            return false
        }
    }

    private func apply(_ updated: Player) {
        player = updated
        usernameInput = updated.username
        balanceInput = String(updated.coinBalance)
    }

    private static func successMessage(for pending: PendingChange, updated: Player) -> String {
        switch (pending.newUsername, pending.newBalance) {
        case (.some, .some):
            return "Spieler „\(updated.username)“ aktualisiert: \(DemonicFormatters.formatCoins(updated.coinBalance)) Coins."
        case (.some, nil):
            return "Username erfolgreich zu „\(updated.username)“ geändert."
        case (nil, .some):
            return "Guthaben von „\(updated.username)“ auf \(DemonicFormatters.formatCoins(updated.coinBalance)) Coins gesetzt."
        case (nil, nil):
            return "Keine Änderungen."
        }
    }
}
