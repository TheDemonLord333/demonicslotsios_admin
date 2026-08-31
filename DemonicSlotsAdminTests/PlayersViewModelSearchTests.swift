//
//  PlayersViewModelSearchTests.swift
//  DemonicSlotsAdminTests
//
//  Case-insensitive local search + alphabetical sort + count label +
//  id-based update matching (so a rename doesn't create a duplicate row).
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct PlayersViewModelSearchTests {
    private func makePlayer(_ username: String, id: String? = nil) -> Player {
        if let id {
            return Player(id: id, username: username, coinBalance: 1)
        }
        return Player(username: username, coinBalance: 1)
    }

    @Test func searchIsCaseInsensitiveAndMatchesSubstrings() {
        let viewModel = PlayersViewModel(
            client: MockAPIClient(),
            initialPlayers: [makePlayer("Alice"), makePlayer("bobby"), makePlayer("Charlie")],
            onUnauthorized: {}
        )

        viewModel.searchText = "ALI"
        #expect(viewModel.filteredPlayers.map(\.username) == ["Alice"])

        viewModel.searchText = "li"
        #expect(Set(viewModel.filteredPlayers.map(\.username)) == Set(["Alice", "Charlie"]))
    }

    @Test func emptySearchReturnsAllSortedAlphabeticallyIgnoringCase() {
        let viewModel = PlayersViewModel(
            client: MockAPIClient(),
            initialPlayers: [makePlayer("zoe"), makePlayer("Adam"), makePlayer("bob")],
            onUnauthorized: {}
        )

        #expect(viewModel.filteredPlayers.map(\.username) == ["Adam", "bob", "zoe"])
    }

    @Test func noMatchesReturnsEmptyFilteredList() {
        let viewModel = PlayersViewModel(
            client: MockAPIClient(),
            initialPlayers: [makePlayer("Adam"), makePlayer("Anna")],
            onUnauthorized: {}
        )

        viewModel.searchText = "zzz"
        #expect(viewModel.filteredPlayers.isEmpty)
    }

    @Test func countLabelReflectsSearchState() {
        let viewModel = PlayersViewModel(
            client: MockAPIClient(),
            initialPlayers: [makePlayer("Adam"), makePlayer("Anna")],
            onUnauthorized: {}
        )

        #expect(viewModel.countLabel == "2 Spieler")

        viewModel.searchText = "Ad"
        #expect(viewModel.countLabel == "1 / 2 Spieler")
    }

    @Test func countLabelIsEmptyWithoutAnyPlayers() {
        let viewModel = PlayersViewModel(client: MockAPIClient(), initialPlayers: [], onUnauthorized: {})
        #expect(viewModel.countLabel == "")
    }

    @Test func applyUpdatedPlayerReplacesExistingEntryById() {
        let viewModel = PlayersViewModel(
            client: MockAPIClient(),
            initialPlayers: [makePlayer("Adam", id: "fixed-id")],
            onUnauthorized: {}
        )

        viewModel.applyUpdatedPlayer(Player(id: "fixed-id", username: "Adam", coinBalance: 999))

        #expect(viewModel.players.count == 1)
        #expect(viewModel.players.first?.coinBalance == 999)
    }

    @Test func applyUpdatedPlayerAfterRenameReplacesRatherThanDuplicates() {
        // Same id, new username (as a real rename would produce) must
        // still match the existing row — matching by the old username
        // would miss it and wrongly append a second entry.
        let viewModel = PlayersViewModel(
            client: MockAPIClient(),
            initialPlayers: [makePlayer("OldName", id: "fixed-id")],
            onUnauthorized: {}
        )

        viewModel.applyUpdatedPlayer(Player(id: "fixed-id", username: "NewName", coinBalance: 1))

        #expect(viewModel.players.count == 1)
        #expect(viewModel.players.first?.username == "NewName")
    }
}
