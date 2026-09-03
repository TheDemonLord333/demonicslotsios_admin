//
//  APIClient.swift
//  DemonicSlotsAdmin
//
//  Thin native URLSession client for the Demonic Slots admin API. The
//  backend and its contract are unchanged (see demonicslotsweb_admin's
//  js/api.js for the reference implementation) — this is purely a native
//  re-implementation of the same endpoints. Players are addressed by
//  their stable `id`; `username` is just a renameable label.
//

import Foundation

/// Abstraction over the admin API so view models can be unit-tested
/// against a mock instead of the network.
protocol AdminAPIClientProtocol {
    func fetchPlayers() async throws -> [Player]
    func fetchPlayer(id: String) async throws -> Player
    func updatePlayer(id: String, fields: PlayerUpdateFields) async throws -> Player
}

@MainActor
final class APIClient: AdminAPIClientProtocol {
    private let baseURL: URL
    private let token: String
    private let session: URLSession
    private let decoder = JSONDecoder()

    /// - Parameters:
    ///   - baseURL: Normalized backend URL (no trailing slash, https only).
    ///   - token: Admin bearer token. Never logged, never surfaced in errors.
    init(baseURL: URL, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    func fetchPlayers() async throws -> [Player] {
        try await send(.players, body: Optional<Data>.none)
    }

    func fetchPlayer(id: String) async throws -> Player {
        try await send(.player(id: id), body: Optional<Data>.none)
    }

    /// One PATCH covering every admin-editable field: `fields` should
    /// contain only the ones that actually changed (any non-empty subset
    /// of username/balance/level/winChanceMultiplier/guaranteedJackpot).
    /// A rename and a balance/level/multiplier/jackpot change made in the
    /// same edit go out as a single request, so there's no risk of one
    /// part succeeding while another targets a since-renamed player under
    /// a stale reference.
    func updatePlayer(id: String, fields: PlayerUpdateFields) async throws -> Player {
        let payload = try JSONEncoder().encode(fields)
        return try await send(.updatePlayer(id: id), body: payload)
    }

    // MARK: - Request plumbing

    private func send<T: Decodable>(_ endpoint: AdminEndpoint, body: Data?) async throws -> T {
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try Self.validate(status: httpResponse.statusCode, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    /// Maps a backend `error` code (400/409 body: `{"error": "..."}`) to a
    /// friendly German message. Matches demonicslotsweb_admin's js/api.js.
    private static let validationMessages: [String: String] = [
        "invalid_username": "Ungültiger Username (3–20 Zeichen: Buchstaben, Zahlen, „_“).",
        "username_taken": "Dieser Username ist bereits vergeben.",
        "invalid_balance": "Ungültiges Guthaben.",
        "invalid_level": "Ungültiges Level (1–100).",
        "invalid_win_chance_multiplier": "Ungültiger Wahrscheinlichkeits-Multiplikator (0,10–2,00).",
        "invalid_guaranteed_jackpot": "Ungültiger Wert für den garantierten Jackpot.",
        "no_fields_to_update": "Keine Änderung zum Speichern.",
    ]

    private static func validate(status: Int, data: Data) throws {
        switch status {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.playerNotFound
        case 400, 409:
            let code = serverErrorCode(from: data)
            let message = code.flatMap { validationMessages[$0] }
                ?? "Ungültige Anfrage\(code.map { " (\($0))" } ?? "")."
            throw APIError.validation(message: message)
        case 500...599:
            throw APIError.serverError(message: serverErrorCode(from: data))
        default:
            throw APIError.unknownStatus(status)
        }
    }

    private static func serverErrorCode(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object["error"] as? String
    }
}
