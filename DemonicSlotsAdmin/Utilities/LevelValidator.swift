//
//  LevelValidator.swift
//  DemonicSlotsAdmin
//
//  Mirrors the backend's level rule: integer 1–100. The Level field in
//  the UI is a Stepper bound to this range, so it can never produce an
//  out-of-range value on its own — `clamp` exists purely to defensively
//  seed that Stepper's initial value from server data, in case a future
//  backend response is ever out of range.
//

import Foundation

enum LevelValidator {
    static let range: ClosedRange<Int> = 1...100

    static func clamp(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
