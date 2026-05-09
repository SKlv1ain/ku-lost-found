//
//  ku_lost_foundApp.swift
//  ku-lost&found
//

import SwiftUI

@main
struct ku_lost_foundApp: App {
    init() {
        KUFonts.register()
    }
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
