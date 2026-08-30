//
//  BackendURLNormalizerTests.swift
//  DemonicSlotsAdminTests
//

import Testing
@testable import DemonicSlotsAdmin

@MainActor
struct BackendURLNormalizerTests {
    @Test func trimsWhitespaceAndTrailingSlashes() {
        let url = BackendURLNormalizer.normalize("  https://demonicslots.thedemonlord333.me/// \n")
        #expect(url?.absoluteString == "https://demonicslots.thedemonlord333.me")
    }

    @Test func rejectsNonHTTPSSchemes() {
        #expect(BackendURLNormalizer.normalize("http://demonicslots.thedemonlord333.me") == nil)
    }

    @Test func rejectsEmptyOrMalformedInput() {
        #expect(BackendURLNormalizer.normalize("") == nil)
        #expect(BackendURLNormalizer.normalize("not a url") == nil)
    }

    @Test func acceptsAlreadyNormalizedURL() {
        let url = BackendURLNormalizer.normalize("https://demonicslots.thedemonlord333.me")
        #expect(url?.absoluteString == "https://demonicslots.thedemonlord333.me")
    }
}
