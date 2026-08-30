//
//  BiometricAuthService.swift
//  DemonicSlotsAdmin
//
//  Optional Face ID / device passcode gate for unlocking a stored session
//  at app start. Only used when the user has enabled it in Settings.
//

import Foundation
import LocalAuthentication

enum BiometricAuthError: Error, LocalizedError {
    case unavailable
    case failed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Face ID oder Gerätecode ist auf diesem Gerät nicht verfügbar."
        case .failed:
            return "Authentifizierung fehlgeschlagen."
        }
    }
}

@MainActor
final class BiometricAuthService {
    /// Whether the device can evaluate Face ID / Touch ID / passcode at all.
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// Prompts Face ID / Touch ID / device passcode. Throws on failure or cancellation.
    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw BiometricAuthError.unavailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evaluationError in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: evaluationError ?? BiometricAuthError.failed)
                }
            }
        }
    }
}
