import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    private let authService = AuthService.shared

    @Published var isAuthenticated = false
    @Published var isApproved = false
    @Published var isPending = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userProfile: User?
    @Published var currentUser: FirebaseAuth.User?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        authService.$currentUser
            .map { $0 != nil }
            .assign(to: &$isAuthenticated)

        authService.$userProfile
            .assign(to: &$userProfile)

        authService.$userProfile
            .map { $0?.approvalStatus == .approved }
            .assign(to: &$isApproved)

        authService.$userProfile
            .map { $0?.approvalStatus == .pending }
            .assign(to: &$isPending)

        authService.$isLoading
            .assign(to: &$isLoading)

        authService.$currentUser
            .assign(to: &$currentUser)
    }

    // MARK: - Auth Actions

    func signUp(email: String, password: String, displayName: String) async {
        errorMessage = nil
        do {
            _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        errorMessage = nil
        do {
            try await authService.resetPassword(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeOnboarding(city: String, skills: [String], lookingFor: [String], availability: Availability, isHireable: Bool) async {
        errorMessage = nil
        do {
            try await authService.completeOnboarding(
                city: city,
                skills: skills,
                lookingFor: lookingFor,
                availability: availability,
                isHireable: isHireable
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateHireableStatus(_ isHireable: Bool) async {
        do {
            try await authService.updateHireableStatus(isHireable)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateUserProfile(_ user: User) async {
        errorMessage = nil
        do {
            try await authService.updateUserProfile(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        errorMessage = nil
        do {
            try await authService.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
