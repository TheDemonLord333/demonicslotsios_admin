//
//  DashboardView.swift
//  DemonicSlotsAdmin
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var session: AppSession
    @StateObject private var viewModel: PlayersViewModel
    @State private var showSettings = false

    private let client: AdminAPIClientProtocol

    init(session: AppSession, client: AdminAPIClientProtocol) {
        self.session = session
        self.client = client
        _viewModel = StateObject(wrappedValue: PlayersViewModel(
            client: client,
            initialPlayers: session.consumeInitialPlayers(),
            onUnauthorized: { [weak session] in session?.handleUnauthorized() }
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicPalette.obsidianBlack.ignoresSafeArea()
                content
            }
            .navigationTitle("Demonic Slots Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Einstellungen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Abmelden") {
                        session.logout()
                    }
                    .foregroundStyle(DemonicPalette.hellfireRed)
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Username suchen …")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(session: session)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            header

            switch viewModel.loadState {
            case .idle, .loading:
                LoadingView(message: "Spieler werden geladen …")
            case .failed(let message):
                ScrollView {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                    .padding()
                }
            case .loaded:
                if viewModel.players.isEmpty {
                    EmptyStateView(text: "Keine Spieler gefunden.", systemImage: "person.3")
                } else if viewModel.filteredPlayers.isEmpty {
                    EmptyStateView(
                        text: "Keine Treffer für „\(viewModel.searchTermForEmptyState)“.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    playerList
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(session.backendURL?.absoluteString ?? session.currentBackendURLString)
                .font(.caption)
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.5))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if !viewModel.countLabel.isEmpty {
                Text(viewModel.countLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.75))
                    .accessibilityLabel(viewModel.countLabel)
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var playerList: some View {
        List {
            ForEach(viewModel.filteredPlayers) { player in
                NavigationLink {
                    PlayerDetailView(
                        player: player,
                        client: client,
                        onUnauthorized: { [weak session] in session?.handleUnauthorized() },
                        onUpdated: { updated in viewModel.applyUpdatedPlayer(updated) }
                    )
                } label: {
                    PlayerRowView(player: player)
                }
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(DemonicPalette.borderSubtle)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.easeInOut(duration: 0.2), value: viewModel.filteredPlayers)
    }
}
