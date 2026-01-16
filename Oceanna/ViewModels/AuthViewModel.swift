import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let authService = AuthService.shared

    init() {
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        // Observe changes from AuthService
        authService.$currentUser
            .map { $0 != nil }
            .assign(to: &$isAuthenticated)

        authService.$userProfile
            .assign(to: &$currentUser)

        authService.$isLoading
            .assign(to: &$isLoading)
    }

    // MARK: - Authentication Methods

    func signUp(email: String, password: String, displayName: String, userType: UserType) async {
        do {
            _ = try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName,
                userType: userType
            )
        } catch let error as AuthError {
            showError(error.errorDescription ?? "Sign up failed")
        } catch {
            showError(error.localizedDescription)
        }
    }

    func signIn(email: String, password: String) async {
        do {
            try await authService.signIn(email: email, password: password)
        } catch let error as AuthError {
            showError(error.errorDescription ?? "Sign in failed")
        } catch {
            showError(error.localizedDescription)
        }
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            showError(error.localizedDescription)
        }
    }

    func resetPassword(email: String) async {
        do {
            try await authService.resetPassword(email: email)
            showError("Password reset email sent. Check your inbox.")
        } catch {
            showError(error.localizedDescription)
        }
    }

    func deleteAccount() async {
        do {
            try await authService.deleteAccount()
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
