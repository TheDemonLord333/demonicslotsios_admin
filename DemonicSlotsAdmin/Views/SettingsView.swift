//
//  SettingsView.swift
//  DemonicSlotsAdmin
//
//  Small settings sheet reachable from the Dashboard toolbar: shows the
//  connected backend URL and the optional Face ID / passcode session lock.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var session: AppSession
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private let biometrics = BiometricAuthService()
    private var isBiometricAvailable: Bool { biometrics.isAvailable() }

    init(session: AppSession) {
        self.session = session
        _settings = ObservedObject(wrappedValue: session.settings)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Face ID / Code beim Start verlangen", isOn: $settings.isFaceIDEnabled)
                        .disabled(!isBiometricAvailable)
                    if !isBiometricAvailable {
                        Text("Face ID oder Gerätecode ist auf diesem Gerät nicht verfügbar.")
                            .font(.caption)
                            .foregroundStyle(DemonicPalette.boneIvory.opacity(0.6))
                    }
                } header: {
                    Text("Sicherheit")
                } footer: {
                    Text("Wenn aktiviert, muss die gespeicherte Sitzung beim nächsten App-Start per Face ID oder Gerätecode entsperrt werden.")
                }
                .listRowBackground(DemonicPalette.darkViolet)

                Section {
                    LabeledContent("Backend-URL") {
                        Text(session.currentBackendURLString)
                            .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
                    }
                } header: {
                    Text("Verbindung")
                }
                .listRowBackground(DemonicPalette.darkViolet)
            }
            .scrollContentBackground(.hidden)
            .background(DemonicPalette.obsidianBlack.ignoresSafeArea())
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
