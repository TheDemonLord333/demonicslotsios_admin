//
//  PlayerDetailViewModel.swift
//  DemonicSlotsAdmin
//
//  All five editable fields (username, balance, level, win-chance
//  multiplier, guaranteed jackpot) are edited together in one form but
//  saved as a single consolidated PATCH — only the fields that actually
//  changed are sent (matches demonicslotsweb_admin's behavior).
//

import Combine
import Foundation

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    /// Only the fields that actually changed are non-nil. Built once the
    /// confirmation dialog is requested, and turned into the wire-format
    /// `PlayerUpdateFields` right before sending.
    struct PendingChange: Identifiable {
        let id = UUID()
        let newUsername: String?
        let newBalance: Int?
        let newLevel: Int?
        let newMultiplier: Double?
        let newGuaranteedJackpot: Bool?

        var isEmpty: Bool {
            newUsername == nil && newBalance == nil && newLevel == nil
                && newMultiplier == nil && newGuaranteedJackpot == nil
        }

        var fields: PlayerUpdateFields {
            PlayerUpdateFields(
                username: newUsername,
                balance: newBalance,
                level: newLevel,
                winChanceMultiplier: newMultiplier,
                guaranteedJackpot: newGuaranteedJackpot
            )
        }
    }

    @Published private(set) var player: Player
    @Published var usernameInput: String
    @Published var balanceInput: String
    /// Bound to a `Stepper(1...100)`, so it's always in range by construction.
    @Published var levelValue: Int
    /// Bound to a `Stepper(0.10...2.00, step: 0.05)`, so it's always in
    /// range by construction.
    @Published var multiplierValue: Double
    @Published var jackpotEnabled: Bool
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
        self.levelValue = LevelValidator.clamp(player.level)
        self.multiplierValue = WinChanceMultiplierValidator.clamp(player.winChanceMultiplier)
        self.jackpotEnabled = player.guaranteedJackpot
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

    private var levelDidChange: Bool { levelValue != player.level }

    private var multiplierDidChange: Bool {
        abs(multiplierValue - player.winChanceMultiplier) > 0.001
    }

    private var jackpotDidChange: Bool { jackpotEnabled != player.guaranteedJackpot }

    /// Username and balance are free-text and must currently be valid
    /// (even if untouched); level/multiplier can't be invalid since
    /// they're Stepper-bound. At least one field must actually differ
    /// from the saved player.
    var canSubmit: Bool {
        guard !isSaving, validatedUsername != nil, validatedBalance != nil else { return false }
        return usernameDidChange || balanceDidChange || levelDidChange || multiplierDidChange || jackpotDidChange
    }

    /// Step 1: validate, then surface a native confirmation dialog before
    /// actually sending a request. Only the fields that changed end up in
    /// `PendingChange`.
    func requestConfirmation() {
        errorMessage = nil
        successMessage = nil

        guard let validatedUsername, let validatedBalance else {
            errorMessage = "Bitte einen gültigen Username (3–20 Zeichen: Buchstaben, Zahlen, „_“) und ein gültiges, nicht-negatives Guthaben angeben."
            return
        }

        let pending = PendingChange(
            newUsername: validatedUsername != player.username ? validatedUsername : nil,
            newBalance: validatedBalance != player.coinBalance ? validatedBalance : nil,
            newLevel: levelDidChange ? levelValue : nil,
            newMultiplier: multiplierDidChange ? multiplierValue : nil,
            newGuaranteedJackpot: jackpotDidChange ? jackpotEnabled : nil
        )
        guard !pending.isEmpty else { return }

        pendingConfirmation = pending
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
        guard !isSaving, !pending.isEmpty else { return false }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        pendingConfirmation = nil
        defer { isSaving = false }

        do {
            let updated = try await client.updatePlayer(id: player.id, fields: pending.fields)
            apply(updated)
            successMessage = Self.successMessage(for: updated)
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

    private func apply(_ updated: Player) {
        player = updated
        usernameInput = updated.username
        balanceInput = String(updated.coinBalance)
        levelValue = LevelValidator.clamp(updated.level)
        multiplierValue = WinChanceMultiplierValidator.clamp(updated.winChanceMultiplier)
        jackpotEnabled = updated.guaranteedJackpot
    }

    private static func successMessage(for updated: Player) -> String {
        let jackpotNote = updated.guaranteedJackpot ? ", Jackpot garantiert 🔥" : ""
        return "„\(updated.username)“ gespeichert: \(DemonicFormatters.formatCoins(updated.coinBalance)) Coins, "
            + "Level \(updated.level), \(DemonicFormatters.formatMultiplier(updated.winChanceMultiplier))×\(jackpotNote)."
    }
}
