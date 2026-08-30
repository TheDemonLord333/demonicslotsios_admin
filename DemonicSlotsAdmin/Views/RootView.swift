//
//  RootView.swift
//  DemonicSlotsAdmin
//
//  Switches between the restoring splash, Login, and Dashboard based on
//  AppSession.state, and kicks off the one-time silent session restore.
//

import SwiftUI

struct RootView: View {
    @StateObject private var settings: AppSettings
    @StateObject private var session: AppSession
    @State private var didAttemptRestore = false

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _session = StateObject(wrappedValue: AppSession(settings: settings))
    }

    var body: some View {
        Group {
            switch session.state {
            case .restoring:
                restoringView
            case .loggedOut(let message):
                LoginView(session: session, initialErrorMessage: message)
            case .loggedIn:
                if let client = session.apiClient {
                    DashboardView(session: session, client: client)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.state)
        .task {
            guard !didAttemptRestore else { return }
            didAttemptRestore = true
            await session.restoreSession()
        }
    }

    private var restoringView: some View {
        ZStack {
            DemonicBackground()
            VStack(spacing: 18) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DemonicPalette.emberOrange)
                    .accessibilityHidden(true)
                ProgressView()
                    .tint(DemonicPalette.glowingViolet)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sitzung wird geprüft …")
    }
}

#Preview {
    RootView()
}
