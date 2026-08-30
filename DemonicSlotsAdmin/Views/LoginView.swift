//
//  LoginView.swift
//  DemonicSlotsAdmin
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var session: AppSession
    @StateObject private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    @State private var appear = false

    private enum Field {
        case url, token
    }

    init(session: AppSession, initialErrorMessage: String?) {
        self.session = session
        _viewModel = StateObject(wrappedValue: LoginViewModel(session: session, initialErrorMessage: initialErrorMessage))
    }

    var body: some View {
        ZStack {
            DemonicBackground()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    formCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 40)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 14)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appear = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DemonicPalette.emberOrange, DemonicPalette.hellfireRed],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: DemonicPalette.emberOrange.opacity(0.5), radius: 16)
                .accessibilityHidden(true)

            Text("Demonic Slots Admin")
                .demonicHeading()
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("Coin-Verwaltung für Spieler von Demonic Slots")
                .font(.subheadline)
                .foregroundStyle(DemonicPalette.boneIvory.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Backend-URL")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
                TextField("https://…", text: $viewModel.backendURLText)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .url)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .token }
                    .demonicField(isFocused: focusedField == .url)
                    .accessibilityLabel("Backend-URL")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Admin-Token")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.7))
                SecureField("Admin-Token", text: $viewModel.tokenText)
                    .textContentType(.password)
                    .focused($focusedField, equals: .token)
                    .submitLabel(.go)
                    .onSubmit { Task { await connect() } }
                    .demonicField(isFocused: focusedField == .token)
                    .accessibilityLabel("Admin-Token")

                Label("Der Token wird sicher in der iOS-Keychain gespeichert.", systemImage: "lock.shield")
                    .font(.caption2)
                    .foregroundStyle(DemonicPalette.boneIvory.opacity(0.55))
            }

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
                    .transition(.opacity)
            }

            DemonicButton(
                title: "Verbinden",
                isLoading: viewModel.isConnecting,
                isDisabled: viewModel.isConnecting
            ) {
                Task { await connect() }
            }
        }
        .demonicCard()
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }

    private func connect() async {
        focusedField = nil
        await viewModel.connect()
    }
}

#Preview {
    LoginView(session: AppSession(settings: AppSettings()), initialErrorMessage: nil)
}
