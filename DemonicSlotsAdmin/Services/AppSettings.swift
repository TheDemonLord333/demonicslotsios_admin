//
//  AppSettings.swift
//  DemonicSlotsAdmin
//
//  Non-sensitive, persisted app preferences. The backend URL is stored
//  here (UserDefaults) for convenience; the admin token never is — it
//  only ever lives in the Keychain (see KeychainService).
//

import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let defaultBackendURLString = "https://demonicslots.thedemonlord333.me"

    private enum Keys {
        static let backendURL = "dsa.backendUrl"
        static let faceIDEnabled = "dsa.faceIDEnabled"
    }

    private let defaults: UserDefaults

    @Published var backendURLString: String {
        didSet { defaults.set(backendURLString, forKey: Keys.backendURL) }
    }

    @Published var isFaceIDEnabled: Bool {
        didSet { defaults.set(isFaceIDEnabled, forKey: Keys.faceIDEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.backendURLString = defaults.string(forKey: Keys.backendURL) ?? Self.defaultBackendURLString
        self.isFaceIDEnabled = defaults.bool(forKey: Keys.faceIDEnabled)
    }
}
