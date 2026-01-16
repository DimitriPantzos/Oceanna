import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case invalidCredentials
    case userNotFound
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .invalidCredentials:
            return "Invalid email or password."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let message):
            return message
        }
    }
}

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: FirebaseAuth.User?
    @Published var userProfile: User?
    @Published var isLoading = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if let userId = user?.uid {
                Task {
                    await self?.fetchUserProfile(userId: userId)
                }
            } else {
                self?.userProfile = nil
            }
        }
    }

    // MARK: - Authentication Methods

    func signUp(email: String, password: String, displayName: String, userType: UserType) async throws -> User {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Create user profile in Firestore
            let user = User(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                userType: userType,
                isVerified: false,
                createdAt: Date()
            )

            try await createUserProfile(user)

            // Create type-specific profile
            if userType == .freelancer {
                try await createFreelancerProfile(userId: result.user.uid)
            } else {
                try await createClientProfile(userId: result.user.uid)
            }

            userProfile = user
            return user
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }

    func signOut() throws {
        try auth.signOut()
        userProfile = nil
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func deleteAccount() async throws {
        guard let user = currentUser else { return }

        // Delete user data from Firestore
        try await db.collection("users").document(user.uid).delete()

        // Delete type-specific profile
        if let profile = userProfile {
            if profile.userType == .freelancer {
                try await db.collection("freelancerProfiles").document(user.uid).delete()
            } else {
                try await db.collection("clientProfiles").document(user.uid).delete()
            }
        }

        // Delete Firebase Auth account
        try await user.delete()
    }

    // MARK: - Profile Methods

    private func createUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user)
    }

    private func createFreelancerProfile(userId: String) async throws {
        let profile = FreelancerProfile(userId: userId)
        try db.collection("freelancerProfiles").document(userId).setData(from: profile)
    }

    private func createClientProfile(userId: String) async throws {
        let profile = ClientProfile(userId: userId)
        try db.collection("clientProfiles").document(userId).setData(from: profile)
    }

    func fetchUserProfile(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            userProfile = try document.data(as: User.self)
        } catch {
            print("Error fetching user profile: \(error.localizedDescription)")
        }
    }

    func updateUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user, merge: true)
        userProfile = user
    }

    // MARK: - Helper Methods

    private func mapAuthError(_ error: NSError) -> AuthError {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return .unknown(error.localizedDescription)
        }

        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .wrongPassword, .invalidCredential:
            return .invalidCredentials
        case .userNotFound:
            return .userNotFound
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
