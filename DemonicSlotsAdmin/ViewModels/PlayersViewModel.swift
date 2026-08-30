//
//  PlayersViewModel.swift
//  DemonicSlotsAdmin
//

import Combine
import Foundation

@MainActor
final class PlayersViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var players: [Player]
    @Published var searchText: String = ""
    @Published private(set) var loadState: LoadState
    @Published private(set) var isRefreshing = false

    private let client: AdminAPIClientProtocol
    private let onUnauthorized: () -> Void

    init(client: AdminAPIClientProtocol, initialPlayers: [Player]? = nil, onUnauthorized: @escaping () -> Void) {
        self.client = client
        self.onUnauthorized = onUnauthorized
        if let initialPlayers {
            self.players = initialPlayers
            self.loadState = .loaded
        } else {
            self.players = []
            self.loadState = .idle
        }
    }

    /// Alphabetically sorted (case-insensitive) and filtered by `searchText`
    /// as a case-insensitive substring match, done entirely locally.
    var filteredPlayers: [Player] {
        let sorted = players.sorted {
            $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending
        }
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return sorted }
        return sorted.filter { $0.username.localizedCaseInsensitiveContains(term) }
    }

    /// "12 Spieler" with no active search, "3 / 12 Spieler" while searching.
    var countLabel: String {
        guard !players.isEmpty else { return "" }
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return "\(players.count) Spieler" }
        return "\(filteredPlayers.count) / \(players.count) Spieler"
    }

    var searchTermForEmptyState: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await load()
    }

    func load() async {
        loadState = .loading
        await fetch()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        await fetch()
        isRefreshing = false
    }

    /// Applies a freshly-saved player (from PlayerDetailView) into the
    /// in-memory list so the Dashboard reflects it immediately on return.
    func applyUpdatedPlayer(_ player: Player) {
        if let index = players.firstIndex(where: { $0.username == player.username }) {
            players[index] = player
        } else {
            players.append(player)
        }
    }

    private func fetch() async {
        do {
            players = try await client.fetchPlayers()
            loadState = .loaded
        } catch let error as APIError {
            if error == .unauthorized {
                onUnauthorized()
                return
            }
            loadState = .failed(error.errorDescription ?? "Unbekannter Fehler.")
        } catch {
            loadState = .failed("Unbekannter Fehler.")
        }
    }
}
