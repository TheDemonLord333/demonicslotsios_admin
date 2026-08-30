//
//  LoginViewModel.swift
//  DemonicSlotsAdmin
//

import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var backendURLText: String
    @Published var tokenText: String = ""
    @Published private(set) var isConnecting = false
    @Published var errorMessage: String?

    private let session: AppSession

    init(session: AppSession, initialErrorMessage: String? = nil) {
        self.session = session
        self.backendURLText = session.currentBackendURLString
        self.errorMessage = initialErrorMessage
    }

    func connect() async {
        guard !isConnecting else { return }
        errorMessage = nil

        let urlText = backendURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !urlText.isEmpty, !token.isEmpty else {
            errorMessage = "Bitte Backend-URL und Admin-Token angeben."
            return
        }

        isConnecting = true
        defer { isConnecting = false }

        do {
            try await session.login(backendURLString: urlText, token: token)
            tokenText = ""
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unbekannter Fehler."
        }
    }
}
