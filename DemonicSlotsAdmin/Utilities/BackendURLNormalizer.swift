//
//  BackendURLNormalizer.swift
//  DemonicSlotsAdmin
//
//  Trims whitespace, strips trailing slashes, and enforces HTTPS —
//  mirroring the web app's `backendUrl.trim().replace(/\/+$/, '')`,
//  plus an explicit HTTPS-only requirement for this native client.
//

import Foundation

enum BackendURLNormalizer {
    static func normalize(_ raw: String) -> URL? {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        guard !trimmed.isEmpty,
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "https",
              let host = components.host,
              !host.isEmpty,
              let url = components.url
        else {
            return nil
        }
        return url
    }
}
