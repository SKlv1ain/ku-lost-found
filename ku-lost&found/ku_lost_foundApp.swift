//
//  ku_lost_foundApp.swift
//  ku-lost&found
//

import SwiftUI

@main
struct ku_lost_foundApp: App {
    @State private var authVM = AuthViewModel()

    init() {
        KUFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isLoading {
                    // Splash / loading while checking stored session
                    launchScreen
                } else if authVM.isAuthenticated {
                    RootView(authVM: authVM)
                } else {
                    AuthScreen(vm: authVM)
                }
            }
            .task { await authVM.bootstrap() }
            .onOpenURL { url in
                authVM.handle(url: url)
            }
        }
    }

    private var launchScreen: some View {
        VStack(spacing: 16) {
            LostFoundLogo()
                .scaleEffect(1.5)
            Text("KU Lost & Found")
                .font(Font.Sarabun.bold(22))
                .foregroundStyle(KUTheme.Palette.neutral900)
            ProgressView()
                .tint(KUTheme.Palette.primary700)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
    }
}
