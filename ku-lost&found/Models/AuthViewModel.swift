import Foundation
import Supabase
import Observation

@Observable
final class AuthViewModel {
    // MARK: - State
    var isAuthenticated = false
    var isLoading = true          // true while we check the stored session
    var email = ""
    var password = ""
    var fullName = ""
    var isSignUp = false          // toggle between Sign In / Sign Up
    var errorMessage: String?
    var isBusy = false            // true during an auth request

    // The current Supabase user (nil when signed out).
    private(set) var user: User?

    // MARK: - Bootstrap
    /// Call once at app launch to restore a persisted session.
    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.session
            user = session.user
            isAuthenticated = true
        } catch {
            // No stored session — stay on auth screen.
            isAuthenticated = false
        }
    }

    // MARK: - Sign Up
    func signUp() async {
        guard validate() else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let response = try await supabase.auth.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                data: ["full_name": .string(fullName.trimmingCharacters(in: .whitespaces))]
            )
            switch response {
            case .session(let session):
                user = session.user
                isAuthenticated = true
            case .user(let u):
                // Email confirmation required — user exists but no session yet
                user = u
                errorMessage = "Check your email to confirm your account."
            }
            clearForm()
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign In
    func signIn() async {
        guard validate() else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let session = try await supabase.auth.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            user = session.user
            isAuthenticated = true
            clearForm()
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Google OAuth
    @MainActor
    func signInWithGoogle() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let session = try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "ku-lost-found://auth-callback")
            )
            user = session.user
            isAuthenticated = true
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign Out
    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            // Even if the remote call fails, clear local state.
        }
        user = nil
        isAuthenticated = false
    }

    // MARK: - Helpers
    private func validate() -> Bool {
        if isSignUp && fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your name."
            return false
        }
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        return true
    }

    private func clearForm() {
        email = ""
        password = ""
        fullName = ""
        errorMessage = nil
    }

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid login") || msg.contains("invalid_credentials") {
            return "Incorrect email or password."
        }
        if msg.contains("already registered") || msg.contains("user_already_exists") {
            return "An account with this email already exists."
        }
        if msg.contains("network") || msg.contains("offline") {
            return "No internet connection. Please try again."
        }
        return "Something went wrong. Please try again."
    }
}
