//
//  AppSession.swift
//  DemonicSlotsAdmin
//
//  Single source of truth for authentication state. Owns the Keychain,
//  persisted settings, and the currently-active API client; orchestrates
//  login, session restore (with optional Face ID gate), and logout so
//  RootView only ever has to switch on `state`.
//

import Combine
import Foundation

@MainActor
final class AppSession: ObservableObject {
    enum State: Equatable {
        case restoring
        case loggedOut(message: String?)
        case loggedIn
    }

    @Published private(set) var state: State = .restoring
    @Published private(set) var backendURL: URL?

    private(set) var apiClient: AdminAPIClientProtocol?
    let settings: AppSettings

    private let keychain: KeychainServicing
    private let biometrics: BiometricAuthService
    private let makeClient: (URL, String) -> AdminAPIClientProtocol
    private var cachedInitialPlayers: [Player]?

    /// Default values for `keychain`/`biometrics`/`makeClient` construct
    /// @MainActor-isolated types, so they can't live as default *parameter*
    /// expressions (those are evaluated in a nonisolated generator context) —
    /// they're resolved here in the init body instead, which does run on
    /// the main actor.
    init(
        settings: AppSettings,
        keychain: KeychainServicing? = nil,
        biometrics: BiometricAuthService? = nil,
        makeClient: (@escaping (URL, String) -> AdminAPIClientProtocol)? = nil
    ) {
        self.settings = settings
        self.keychain = keychain ?? KeychainService()
        self.biometrics = biometrics ?? BiometricAuthService()
        self.makeClient = makeClient ?? { APIClient(baseURL: $0, token: $1) }
    }

    var currentBackendURLString: String { settings.backendURLString }

    /// Players fetched as part of the login connectivity check, handed to
    /// the Dashboard once so it doesn't need to re-fetch immediately after
    /// login. Consumed (cleared) on read.
    func consumeInitialPlayers() -> [Player]? {
        defer { cachedInitialPlayers = nil }
        return cachedInitialPlayers
    }

    /// Called once at app start: loads any stored URL/token, optionally
    /// requires Face ID/passcode, then validates the token against the
    /// backend before showing the Dashboard.
    func restoreSession() async {
        guard let url = BackendURLNormalizer.normalize(settings.backendURLString) else {
            state = .loggedOut(message: nil)
            return
        }

        let storedToken: String?
        do {
            storedToken = try keychain.loadToken()
        } catch {
            storedToken = nil
        }

        guard let token = storedToken, !token.isEmpty else {
            state = .loggedOut(message: nil)
            return
        }

        if settings.isFaceIDEnabled {
            do {
                try await biometrics.authenticate(reason: "Entsperre Demonic Slots Admin")
            } catch {
                state = .loggedOut(message: nil)
                return
            }
        }

        let client = makeClient(url, token)
        do {
            let players = try await client.fetchPlayers()
            apiClient = client
            backendURL = url
            cachedInitialPlayers = players
            state = .loggedIn
        } catch {
            try? keychain.deleteToken()
            state = .loggedOut(message: "Sitzung abgelaufen oder Token ungültig. Bitte erneut anmelden.")
        }
    }

    /// Validates backend URL + token against the backend, and only on
    /// success persists them (URL in UserDefaults, token in Keychain).
    func login(backendURLString: String, token: String) async throws {
        guard let url = BackendURLNormalizer.normalize(backendURLString) else {
            throw APIError.invalidURL
        }
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            throw APIError.validation(message: "Bitte Backend-URL und Admin-Token angeben.")
        }

        let client = makeClient(url, trimmedToken)
        let players = try await client.fetchPlayers()

        try keychain.save(token: trimmedToken)
        settings.backendURLString = url.absoluteString

        apiClient = client
        backendURL = url
        cachedInitialPlayers = players
        state = .loggedIn
    }

    /// Logs out, clearing the token from the Keychain and all in-memory
    /// player data. The backend URL is kept for a more convenient re-login.
    func logout() {
        try? keychain.deleteToken()
        apiClient = nil
        backendURL = nil
        cachedInitialPlayers = nil
        state = .loggedOut(message: nil)
    }

    /// Called by any view model when a request comes back 401.
    func handleUnauthorized() {
        try? keychain.deleteToken()
        apiClient = nil
        backendURL = nil
        cachedInitialPlayers = nil
        state = .loggedOut(message: "Sitzung abgelaufen oder Token ungültig. Bitte erneut anmelden.")
    }
}
