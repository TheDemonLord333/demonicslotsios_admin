//
//  APIClient.swift
//  DemonicSlotsAdmin
//
//  Thin native URLSession client for the Demonic Slots admin API. The
//  backend and its contract are unchanged (see demonicslotsweb_admin's
//  js/api.js for the reference implementation) — this is purely a native
//  re-implementation of the same three endpoints.
//

import Foundation

/// Abstraction over the admin API so view models can be unit-tested
/// against a mock instead of the network.
protocol AdminAPIClientProtocol {
    func fetchPlayers() async throws -> [Player]
    func fetchPlayer(username: String) async throws -> Player
    func updateBalance(username: String, balance: Int) async throws -> Player
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

    func fetchPlayer(username: String) async throws -> Player {
        try await send(.player(username: username), body: Optional<Data>.none)
    }

    func updateBalance(username: String, balance: Int) async throws -> Player {
        let payload = try JSONEncoder().encode(["balance": balance])
        return try await send(.updateBalance(username: username), body: payload)
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

    private static func validate(status: Int, data: Data) throws {
        switch status {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.playerNotFound
        case 400, 422:
            throw APIError.validation(message: serverMessage(from: data) ?? "Ungültige Eingabe.")
        case 500...599:
            throw APIError.serverError(message: serverMessage(from: data))
        default:
            throw APIError.unknownStatus(status)
        }
    }

    private static func serverMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object["error"] as? String
    }
}
