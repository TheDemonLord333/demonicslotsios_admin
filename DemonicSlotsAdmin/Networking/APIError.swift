//
//  APIError.swift
//  DemonicSlotsAdmin
//
//  Typed error surface for the admin API. Messages are user-facing German
//  text and never include the token or other sensitive request details.
//

import Foundation

enum APIError: Error, Equatable {
    /// Backend URL couldn't be turned into a valid HTTPS URL.
    case invalidURL
    /// The request failed at the transport level (no connection, DNS, TLS, timeout, …).
    case network(String)
    /// HTTP 401 — missing or invalid admin token.
    case unauthorized
    /// HTTP 404 — the requested player does not exist (or was deleted since).
    case playerNotFound
    /// HTTP 400/409 — the server rejected the request body (invalid/taken
    /// username, invalid balance, …).
    case validation(message: String)
    /// HTTP 5xx.
    case serverError(message: String?)
    /// The response wasn't even a valid HTTP response.
    case invalidResponse
    /// The response body could not be parsed as the expected JSON shape.
    case decoding(String)
    /// Any other, unmapped HTTP status code.
    case unknownStatus(Int)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Backend-URL. Bitte prüfe die Adresse (https://…)."
        case .network:
            return "Netzwerkfehler – Server nicht erreichbar. Prüfe die Backend-URL und deine Internetverbindung."
        case .unauthorized:
            return "Ungültiger oder abgelaufener Admin-Token."
        case .playerNotFound:
            return "Spieler wurde nicht gefunden (evtl. wurde er zwischenzeitlich gelöscht)."
        case .validation(let message):
            return message
        case .serverError(let message):
            if let message, !message.isEmpty {
                return "Serverfehler (\(message)). Ist ADMIN_TOKEN auf dem Server konfiguriert?"
            }
            return "Serverfehler. Ist ADMIN_TOKEN auf dem Server konfiguriert?"
        case .invalidResponse, .decoding:
            return "Antwort des Servers konnte nicht gelesen werden."
        case .unknownStatus(let code):
            return "Unerwarteter Fehler (Status \(code))."
        }
    }
}
