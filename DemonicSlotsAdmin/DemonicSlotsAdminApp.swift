//
//  DemonicSlotsAdminApp.swift
//  DemonicSlotsAdmin
//
//  Created by David Martens on 21.08.26.
//

import SwiftUI

@main
struct DemonicSlotsAdminApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                // The demonic theme is dark-only, independent of the
                // system appearance setting.
                .preferredColorScheme(.dark)
        }
    }
}
