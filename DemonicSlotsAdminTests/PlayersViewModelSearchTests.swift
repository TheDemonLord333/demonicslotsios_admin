//
//  PlayersViewModelSearchTests.swift
//  DemonicSlotsAdminTests
//
//  Case-insensitive local search + alphabetical sort + count label.
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct PlayersViewModelSearchTests {
    private func makePlayer(_ username: String) -> Player {
        Player(username: username, coinBalance: 1)
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

    @Test func applyUpdatedPlayerReplacesExistingEntry() {
        let viewModel = PlayersViewModel(
            client: MockAPIClient(),
            initialPlayers: [makePlayer("Adam")],
            onUnauthorized: {}
        )

        viewModel.applyUpdatedPlayer(Player(username: "Adam", coinBalance: 999))

        #expect(viewModel.players.first?.coinBalance == 999)
    }
}
