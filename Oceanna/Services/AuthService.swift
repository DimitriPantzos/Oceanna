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
    case notApproved
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
        case .notApproved:
            return "Your profile is pending review."
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

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var isApproved: Bool {
        userProfile?.approvalStatus == .approved
    }

    var isPending: Bool {
        userProfile?.approvalStatus == .pending
    }

    var isWaitlisted: Bool {
        userProfile?.approvalStatus == .waitlisted
    }

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

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }

        print("AuthService: Starting signup for \(email)")
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            print("AuthService: User created successfully: \(result.user.uid)")

            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            let user = User(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                approvalStatus: .pending
            )

            try await createUserProfile(user)
            userProfile = user
            return user
        } catch let error as NSError {
            print("AuthService: Signup error: \(error.localizedDescription)")
            throw mapAuthError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        print("AuthService: Starting signin for \(email)")
        do {
            try await auth.signIn(withEmail: email, password: password)
            print("AuthService: Signin successful")
        } catch let error as NSError {
            print("AuthService: Signin error: \(error.localizedDescription)")
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
        try await db.collection("users").document(user.uid).delete()
        try await user.delete()
    }

    // MARK: - Profile Methods

    private func createUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user)
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

    func updateHireableStatus(_ isHireable: Bool) async throws {
        guard var profile = userProfile else { return }
        profile.isHireable = isHireable
        try await updateUserProfile(profile)
    }

    func completeOnboarding(city: String, skills: [String], lookingFor: [String], availability: Availability, isHireable: Bool) async throws {
        guard var profile = userProfile else { return }
        profile.city = city
        profile.skills = skills
        profile.lookingFor = lookingFor
        profile.availability = availability
        profile.isHireable = isHireable
        try await updateUserProfile(profile)
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
