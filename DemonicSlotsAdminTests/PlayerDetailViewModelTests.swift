//
//  PlayerDetailViewModelTests.swift
//  DemonicSlotsAdminTests
//
//  The consolidated single-PATCH save flow: only changed fields are sent,
//  canSubmit gates on validity + an actual change, and a 401 logs out
//  instead of surfacing an error banner.
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct PlayerDetailViewModelTests {
    private func makePlayer() -> Player {
        Player(
            id: "player-1",
            username: "Alice",
            coinBalance: 1000,
            level: 5,
            winChanceMultiplier: 1.0,
            guaranteedJackpot: false
        )
    }

    @Test func canSubmitIsFalseWithoutAnyChange() {
        let viewModel = PlayerDetailViewModel(player: makePlayer(), client: MockAPIClient(), onUnauthorized: {}, onUpdated: { _ in })
        #expect(viewModel.canSubmit == false)
    }

    @Test func canSubmitIsTrueOnceBalanceChanges() {
        let viewModel = PlayerDetailViewModel(player: makePlayer(), client: MockAPIClient(), onUnauthorized: {}, onUpdated: { _ in })
        viewModel.balanceInput = "2000"
        #expect(viewModel.canSubmit == true)
    }

    @Test func canSubmitIsFalseWithInvalidUsernameEvenIfBalanceChanged() {
        let viewModel = PlayerDetailViewModel(player: makePlayer(), client: MockAPIClient(), onUnauthorized: {}, onUpdated: { _ in })
        viewModel.usernameInput = "a" // too short
        viewModel.balanceInput = "2000"
        #expect(viewModel.canSubmit == false)
    }

    @Test func requestConfirmationOnlyIncludesChangedFields() {
        let viewModel = PlayerDetailViewModel(player: makePlayer(), client: MockAPIClient(), onUnauthorized: {}, onUpdated: { _ in })
        viewModel.balanceInput = "2000"
        viewModel.jackpotEnabled = true
        // username/level/multiplier left untouched.

        viewModel.requestConfirmation()

        let pending = viewModel.pendingConfirmation
        #expect(pending?.newBalance == 2000)
        #expect(pending?.newGuaranteedJackpot == true)
        #expect(pending?.newUsername == nil)
        #expect(pending?.newLevel == nil)
        #expect(pending?.newMultiplier == nil)
    }

    @Test func requestConfirmationDoesNothingWithoutChanges() {
        let viewModel = PlayerDetailViewModel(player: makePlayer(), client: MockAPIClient(), onUnauthorized: {}, onUpdated: { _ in })
        viewModel.requestConfirmation()
        #expect(viewModel.pendingConfirmation == nil)
    }

    @Test func confirmSaveSendsOnlyChangedFieldsInOneRequest() async throws {
        let mock = MockAPIClient()
        mock.updatePlayerResult = .success(Player(
            id: "player-1", username: "Alice", coinBalance: 2000,
            level: 5, winChanceMultiplier: 1.0, guaranteedJackpot: false, adminRevision: 2
        ))
        let viewModel = PlayerDetailViewModel(player: makePlayer(), client: mock, onUnauthorized: {}, onUpdated: { _ in })
        viewModel.balanceInput = "2000"
        viewModel.requestConfirmation()
        let pending = try #require(viewModel.pendingConfirmation)

        let success = await viewModel.confirmSave(pending)

        #expect(success == true)
        #expect(mock.lastUpdatePlayerId == "player-1")
        #expect(mock.lastUpdatePlayerFields == PlayerUpdateFields(balance: 2000))
        #expect(viewModel.player.coinBalance == 2000)
        #expect(viewModel.successMessage != nil)
    }

    @Test func confirmSaveOnUnauthorizedLogsOutWithoutSettingErrorMessage() async throws {
        let mock = MockAPIClient()
        mock.updatePlayerResult = .failure(APIError.unauthorized)
        var didCallUnauthorized = false
        let viewModel = PlayerDetailViewModel(
            player: makePlayer(),
            client: mock,
            onUnauthorized: { didCallUnauthorized = true },
            onUpdated: { _ in }
        )
        viewModel.balanceInput = "2000"
        viewModel.requestConfirmation()
        let pending = try #require(viewModel.pendingConfirmation)

        let success = await viewModel.confirmSave(pending)

        #expect(success == false)
        #expect(didCallUnauthorized == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func confirmSaveOnValidationErrorKeepsPreviousPlayerData() async throws {
        let mock = MockAPIClient()
        mock.updatePlayerResult = .failure(APIError.validation(message: "Dieser Username ist bereits vergeben."))
        let viewModel = PlayerDetailViewModel(player: makePlayer(), client: mock, onUnauthorized: {}, onUpdated: { _ in })
        viewModel.usernameInput = "Taken"
        viewModel.requestConfirmation()
        let pending = try #require(viewModel.pendingConfirmation)

        let success = await viewModel.confirmSave(pending)

        #expect(success == false)
        #expect(viewModel.errorMessage == "Dieser Username ist bereits vergeben.")
        #expect(viewModel.player.username == "Alice")
    }
}
