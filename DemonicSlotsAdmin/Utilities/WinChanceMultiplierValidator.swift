//
//  WinChanceMultiplierValidator.swift
//  DemonicSlotsAdmin
//
//  Mirrors the backend's win-chance-multiplier rule: 0.10–2.00 (1.0 =
//  neutral). The multiplier field in the UI is a Stepper bound to this
//  range, so it can never produce an out-of-range value on its own —
//  `clamp` exists purely to defensively seed that Stepper's initial
//  value from server data, in case a future backend response is ever
//  out of range.
//

import Foundation

enum WinChanceMultiplierValidator {
    static let range: ClosedRange<Double> = 0.10...2.00

    static func clamp(_ value: Double) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
