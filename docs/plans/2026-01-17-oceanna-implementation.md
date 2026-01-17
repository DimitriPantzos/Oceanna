# Oceanna Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild Oceanna as a curated creative marketplace with swipe-based discovery, follow-based feed, and unified profiles with hireable toggle.

**Architecture:** SwiftUI + MVVM with Firebase backend. Unified User model (no separate freelancer/client profiles). Connection-gated features. Monochrome design system.

**Tech Stack:** SwiftUI, Firebase Auth, Cloud Firestore, Cloud Storage, iOS 17+

---

## Phase 1: Design System & Core Models

### Task 1: Create Design System

**Files:**
- Create: `Oceanna/Core/Design/OceannaTheme.swift`

**Step 1: Create the design system file**

```swift
import SwiftUI

// MARK: - Oceanna Design System
// Minimal, premium aesthetic inspired by Erewhon / Le Labo / Apple

struct OceannaTheme {
    // MARK: - Colors (Pure Monochrome)
    struct Colors {
        static let primary = Color.black
        static let background = Color.white
        static let secondaryBackground = Color(uiColor: .systemGray6)
        static let tertiaryBackground = Color(uiColor: .systemGray5)
        static let primaryText = Color.black
        static let secondaryText = Color(uiColor: .systemGray)
        static let tertiaryText = Color(uiColor: .systemGray2)
        static let border = Color(uiColor: .systemGray4)
        static let divider = Color(uiColor: .systemGray5)
    }

    // MARK: - Typography
    struct Typography {
        // UI Text - SF Pro
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)

        // Monospace - SF Mono (for tags, skills, metadata)
        static let monoLarge = Font.system(size: 15, weight: .medium, design: .monospaced)
        static let mono = Font.system(size: 13, weight: .medium, design: .monospaced)
        static let monoSmall = Font.system(size: 11, weight: .medium, design: .monospaced)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Card Style
    struct Card {
        static let borderWidth: CGFloat = 1
        static let padding: CGFloat = 16
        static let imagePadding: CGFloat = 12  // White frame around images
    }
}

// MARK: - View Modifiers

struct OceannaButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OceannaTheme.Typography.headline)
            .foregroundColor(isPrimary ? .white : OceannaTheme.Colors.primary)
            .padding(.horizontal, OceannaTheme.Spacing.lg)
            .padding(.vertical, OceannaTheme.Spacing.sm)
            .background(isPrimary ? OceannaTheme.Colors.primary : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: OceannaTheme.Radius.sm)
                    .stroke(OceannaTheme.Colors.primary, lineWidth: isPrimary ? 0 : 1)
            )
            .cornerRadius(OceannaTheme.Radius.sm)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MonoTagStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(OceannaTheme.Typography.mono)
            .foregroundColor(OceannaTheme.Colors.primaryText)
            .padding(.horizontal, OceannaTheme.Spacing.xs)
            .padding(.vertical, OceannaTheme.Spacing.xxs)
            .background(OceannaTheme.Colors.secondaryBackground)
            .cornerRadius(OceannaTheme.Radius.xs)
    }
}

extension View {
    func oceannaButton(isPrimary: Bool = true) -> some View {
        buttonStyle(OceannaButtonStyle(isPrimary: isPrimary))
    }

    func monoTag() -> some View {
        modifier(MonoTagStyle())
    }
}
```

**Step 2: Verify file compiles**

Run: `cd /Users/dimitriospantzos/Oceanna && xcodebuild -scheme Oceanna -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Oceanna/Core/Design/OceannaTheme.swift
git commit -m "feat: add Oceanna design system with monochrome theme"
```

---

### Task 2: Update User Model

**Files:**
- Modify: `Oceanna/Models/User.swift`

**Step 1: Rewrite User model with unified structure**

Replace entire contents of `Oceanna/Models/User.swift`:

```swift
import Foundation
import FirebaseFirestore

// MARK: - Availability
enum Availability: String, Codable, CaseIterable {
    case inPerson = "in_person"
    case remote = "remote"
    case both = "both"

    var displayName: String {
        switch self {
        case .inPerson: return "In-Person"
        case .remote: return "Remote"
        case .both: return "In-Person & Remote"
        }
    }
}

// MARK: - Approval Status
enum ApprovalStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case waitlisted = "waitlisted"
}

// MARK: - Profile Visibility
struct ProfileVisibility: Codable {
    var showSkills: Bool = true
    var showPortfolio: Bool = true
    var showBio: Bool = true
    var showCity: Bool = true

    init(showSkills: Bool = true, showPortfolio: Bool = true, showBio: Bool = true, showCity: Bool = true) {
        self.showSkills = showSkills
        self.showPortfolio = showPortfolio
        self.showBio = showBio
        self.showCity = showCity
    }
}

// MARK: - User Model
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var avatarUrl: String?
    var city: String
    var isHireable: Bool
    var availability: Availability
    var skills: [String]
    var lookingFor: [String]
    var bio: String?
    var isVerified: Bool
    var approvalStatus: ApprovalStatus
    var visibility: ProfileVisibility
    var createdAt: Date

    var initials: String {
        let names = displayName.split(separator: " ")
        let firstInitial = names.first?.first ?? "?"
        let lastInitial = names.count > 1 ? names.last?.first : nil
        return "\(firstInitial)\(lastInitial ?? Character(""))"
    }

    var availabilityBadge: String {
        "\(city) · \(availability.displayName)"
    }

    var topSkill: String? {
        skills.first
    }

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        avatarUrl: String? = nil,
        city: String = "",
        isHireable: Bool = true,
        availability: Availability = .both,
        skills: [String] = [],
        lookingFor: [String] = [],
        bio: String? = nil,
        isVerified: Bool = false,
        approvalStatus: ApprovalStatus = .pending,
        visibility: ProfileVisibility = ProfileVisibility(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.city = city
        self.isHireable = isHireable
        self.availability = availability
        self.skills = skills
        self.lookingFor = lookingFor
        self.bio = bio
        self.isVerified = isVerified
        self.approvalStatus = approvalStatus
        self.visibility = visibility
        self.createdAt = createdAt
    }
}

extension User {
    static let example = User(
        id: "user123",
        email: "sarah@example.com",
        displayName: "Sarah Chen",
        city: "Brooklyn, NY",
        isHireable: true,
        availability: .both,
        skills: ["UI/UX Design", "Figma", "Branding"],
        lookingFor: ["Photography", "Illustration"],
        bio: "Creative director with a passion for minimal design.",
        isVerified: true,
        approvalStatus: .approved
    )

    static let pendingExample = User(
        id: "user456",
        email: "pending@example.com",
        displayName: "New User",
        city: "Los Angeles, CA",
        approvalStatus: .pending
    )
}
```

**Step 2: Verify file compiles**

Run: `cd /Users/dimitriospantzos/Oceanna && xcodebuild -scheme Oceanna -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -30`
Expected: Compilation errors (other files reference old UserType) - this is expected

**Step 3: Commit partial progress**

```bash
git add Oceanna/Models/User.swift
git commit -m "feat: update User model with unified profile and hireable toggle"
```

---

### Task 3: Create Connection Model

**Files:**
- Create: `Oceanna/Models/Connection.swift`

**Step 1: Create Connection model**

```swift
import Foundation
import FirebaseFirestore

enum ConnectionStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case ignored = "ignored"
}

struct Connection: Identifiable, Codable {
    @DocumentID var id: String?
    var requesterId: String
    var receiverId: String
    var status: ConnectionStatus
    var createdAt: Date
    var acceptedAt: Date?

    init(
        id: String? = nil,
        requesterId: String,
        receiverId: String,
        status: ConnectionStatus = .pending,
        createdAt: Date = Date(),
        acceptedAt: Date? = nil
    ) {
        self.id = id
        self.requesterId = requesterId
        self.receiverId = receiverId
        self.status = status
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
    }
}

extension Connection {
    static let example = Connection(
        id: "conn123",
        requesterId: "user1",
        receiverId: "user2",
        status: .accepted,
        acceptedAt: Date()
    )
}
```

**Step 2: Commit**

```bash
git add Oceanna/Models/Connection.swift
git commit -m "feat: add Connection model for user connections"
```

---

### Task 4: Create PortfolioItem Model

**Files:**
- Create: `Oceanna/Models/PortfolioItem.swift`

**Step 1: Create PortfolioItem model**

```swift
import Foundation
import FirebaseFirestore

struct PortfolioItem: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var imageUrl: String
    var title: String
    var description: String?
    var tags: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        userId: String,
        imageUrl: String,
        title: String,
        description: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageUrl = imageUrl
        self.title = title
        self.description = description
        self.tags = tags
        self.createdAt = createdAt
    }
}

extension PortfolioItem {
    static let example = PortfolioItem(
        id: "portfolio123",
        userId: "user123",
        imageUrl: "https://example.com/image.jpg",
        title: "Brand Identity for Coffee Shop",
        description: "Complete visual identity including logo, packaging, and signage.",
        tags: ["Branding", "Logo Design", "Packaging"]
    )
}
```

**Step 2: Commit**

```bash
git add Oceanna/Models/PortfolioItem.swift
git commit -m "feat: add PortfolioItem model"
```

---

### Task 5: Update FeedPost Model

**Files:**
- Modify: `Oceanna/Models/FeedPost.swift`

**Step 1: Read current file and update**

Replace contents with updated post types:

```swift
import Foundation
import FirebaseFirestore

enum PostType: String, Codable, CaseIterable {
    case portfolio = "portfolio"
    case update = "update"
    case wip = "wip"
    case opportunity = "opportunity"
    case collaboration = "collaboration"
    case milestone = "milestone"
    case question = "question"

    var displayName: String {
        switch self {
        case .portfolio: return "Work"
        case .update: return "Update"
        case .wip: return "In Progress"
        case .opportunity: return "Opportunity"
        case .collaboration: return "Collab"
        case .milestone: return "Milestone"
        case .question: return "Question"
        }
    }

    var icon: String {
        switch self {
        case .portfolio: return "photo"
        case .update: return "text.bubble"
        case .wip: return "hammer"
        case .opportunity: return "briefcase"
        case .collaboration: return "person.2"
        case .milestone: return "star"
        case .question: return "questionmark.circle"
        }
    }
}

struct OpportunityDetails: Codable {
    var budget: String?
    var timeline: String?
    var locationPreference: Availability
    var skillsNeeded: [String]

    init(budget: String? = nil, timeline: String? = nil, locationPreference: Availability = .both, skillsNeeded: [String] = []) {
        self.budget = budget
        self.timeline = timeline
        self.locationPreference = locationPreference
        self.skillsNeeded = skillsNeeded
    }
}

struct FeedPost: Identifiable, Codable {
    @DocumentID var id: String?
    var authorId: String
    var postType: PostType
    var content: String
    var mediaUrls: [String]
    var tags: [String]
    var opportunityDetails: OpportunityDetails?
    var interestedUserIds: [String]
    var applicantIds: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        authorId: String,
        postType: PostType,
        content: String,
        mediaUrls: [String] = [],
        tags: [String] = [],
        opportunityDetails: OpportunityDetails? = nil,
        interestedUserIds: [String] = [],
        applicantIds: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.authorId = authorId
        self.postType = postType
        self.content = content
        self.mediaUrls = mediaUrls
        self.tags = tags
        self.opportunityDetails = opportunityDetails
        self.interestedUserIds = interestedUserIds
        self.applicantIds = applicantIds
        self.createdAt = createdAt
    }

    var isOpportunity: Bool {
        postType == .opportunity
    }
}

extension FeedPost {
    static let portfolioExample = FeedPost(
        id: "post1",
        authorId: "user123",
        postType: .portfolio,
        content: "Just wrapped up this brand identity project. Really happy with how the color palette came together.",
        mediaUrls: ["https://example.com/work1.jpg"],
        tags: ["Branding", "Identity"]
    )

    static let opportunityExample = FeedPost(
        id: "post2",
        authorId: "user456",
        postType: .opportunity,
        content: "Looking for a photographer for a product shoot this Saturday. Natural light, minimal aesthetic.",
        opportunityDetails: OpportunityDetails(
            budget: "$500-800",
            timeline: "This weekend",
            locationPreference: .inPerson,
            skillsNeeded: ["Product Photography", "Lighting"]
        )
    )
}
```

**Step 2: Commit**

```bash
git add Oceanna/Models/FeedPost.swift
git commit -m "feat: update FeedPost model with opportunity details and engagement tracking"
```

---

### Task 6: Update Message Model

**Files:**
- Modify: `Oceanna/Models/Message.swift`

**Step 1: Update Message model with milestone support**

Replace contents:

```swift
import Foundation
import FirebaseFirestore

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case quote = "quote"
    case proposal = "proposal"
    case milestone = "milestone"
    case completion = "completion"
}

enum MilestoneStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
}

struct MilestoneData: Codable {
    var title: String
    var amount: String?
    var status: MilestoneStatus

    init(title: String, amount: String? = nil, status: MilestoneStatus = .pending) {
        self.title = title
        self.amount = amount
        self.status = status
    }
}

struct QuoteData: Codable {
    var description: String
    var amount: String
    var validUntil: Date?

    init(description: String, amount: String, validUntil: Date? = nil) {
        self.description = description
        self.amount = amount
        self.validUntil = validUntil
    }
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var content: String
    var messageType: MessageType
    var attachments: [String]
    var quoteData: QuoteData?
    var milestoneData: MilestoneData?
    var createdAt: Date

    init(
        id: String? = nil,
        conversationId: String,
        senderId: String,
        content: String,
        messageType: MessageType = .text,
        attachments: [String] = [],
        quoteData: QuoteData? = nil,
        milestoneData: MilestoneData? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.messageType = messageType
        self.attachments = attachments
        self.quoteData = quoteData
        self.milestoneData = milestoneData
        self.createdAt = createdAt
    }
}

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participantIds: [String]
    var projectReference: String?
    var lastMessage: String?
    var lastMessageAt: Date?
    var unreadCounts: [String: Int]
    var isCompleted: Bool
    var completionConfirmedBy: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        participantIds: [String],
        projectReference: String? = nil,
        lastMessage: String? = nil,
        lastMessageAt: Date? = nil,
        unreadCounts: [String: Int] = [:],
        isCompleted: Bool = false,
        completionConfirmedBy: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participantIds = participantIds
        self.projectReference = projectReference
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCounts = unreadCounts
        self.isCompleted = isCompleted
        self.completionConfirmedBy = completionConfirmedBy
        self.createdAt = createdAt
    }

    func otherParticipantId(currentUserId: String) -> String? {
        participantIds.first { $0 != currentUserId }
    }

    func unreadCount(for userId: String) -> Int {
        unreadCounts[userId] ?? 0
    }

    var canLeaveReview: Bool {
        completionConfirmedBy.count == 2
    }
}

extension Message {
    static let example = Message(
        id: "msg1",
        conversationId: "conv1",
        senderId: "user1",
        content: "Hey! I'd love to work on this project with you."
    )

    static let quoteExample = Message(
        id: "msg2",
        conversationId: "conv1",
        senderId: "user1",
        content: "Here's my quote for the project:",
        messageType: .quote,
        quoteData: QuoteData(description: "Brand identity package", amount: "$1,500")
    )
}

extension Conversation {
    static let example = Conversation(
        id: "conv1",
        participantIds: ["user1", "user2"],
        lastMessage: "Sounds great, let's do it!",
        lastMessageAt: Date()
    )
}
```

**Step 2: Commit**

```bash
git add Oceanna/Models/Message.swift
git commit -m "feat: update Message model with quotes, milestones, and completion tracking"
```

---

### Task 7: Update Review Model

**Files:**
- Modify: `Oceanna/Models/Review.swift`

**Step 1: Update Review model with category ratings**

Replace contents:

```swift
import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var reviewerId: String
    var revieweeId: String
    var conversationId: String
    var qualityRating: Int
    var communicationRating: Int
    var timelinessRating: Int
    var content: String?
    var createdAt: Date

    var averageRating: Double {
        Double(qualityRating + communicationRating + timelinessRating) / 3.0
    }

    init(
        id: String? = nil,
        reviewerId: String,
        revieweeId: String,
        conversationId: String,
        qualityRating: Int,
        communicationRating: Int,
        timelinessRating: Int,
        content: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reviewerId = reviewerId
        self.revieweeId = revieweeId
        self.conversationId = conversationId
        self.qualityRating = min(5, max(1, qualityRating))
        self.communicationRating = min(5, max(1, communicationRating))
        self.timelinessRating = min(5, max(1, timelinessRating))
        self.content = content
        self.createdAt = createdAt
    }
}

extension Review {
    static let example = Review(
        id: "review1",
        reviewerId: "user1",
        revieweeId: "user2",
        conversationId: "conv1",
        qualityRating: 5,
        communicationRating: 5,
        timelinessRating: 4,
        content: "Amazing work! Sarah delivered exactly what we discussed and was super responsive throughout."
    )
}
```

**Step 2: Commit**

```bash
git add Oceanna/Models/Review.swift
git commit -m "feat: update Review model with category ratings"
```

---

### Task 8: Delete Obsolete Models

**Files:**
- Delete: `Oceanna/Models/FreelancerProfile.swift`
- Delete: `Oceanna/Models/ClientProfile.swift`
- Delete: `Oceanna/Models/Project.swift`
- Delete: `Oceanna/Models/Location.swift`

**Step 1: Remove obsolete files**

```bash
rm Oceanna/Models/FreelancerProfile.swift
rm Oceanna/Models/ClientProfile.swift
rm Oceanna/Models/Project.swift
rm Oceanna/Models/Location.swift
```

**Step 2: Commit**

```bash
git add -A
git commit -m "chore: remove obsolete models (FreelancerProfile, ClientProfile, Project, Location)"
```

---

## Phase 2: Services Layer

### Task 9: Update AuthService

**Files:**
- Modify: `Oceanna/Services/AuthService.swift`

**Step 1: Rewrite AuthService with new User model**

Replace contents:

```swift
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

        do {
            let result = try await auth.createUser(withEmail: email, password: password)

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
```

**Step 2: Commit**

```bash
git add Oceanna/Services/AuthService.swift
git commit -m "feat: update AuthService with unified User model and approval status"
```

---

### Task 10: Create ConnectionService

**Files:**
- Create: `Oceanna/Services/ConnectionService.swift`

**Step 1: Create ConnectionService**

```swift
import Foundation
import FirebaseFirestore

@MainActor
class ConnectionService: ObservableObject {
    static let shared = ConnectionService()

    @Published var connections: [Connection] = []
    @Published var pendingRequests: [Connection] = []
    @Published var connectedUserIds: Set<String> = []
    @Published var isLoading = false

    private let db = Firestore.firestore()

    // MARK: - Connection Actions

    func sendConnectionRequest(to receiverId: String, from requesterId: String) async throws {
        let connection = Connection(
            requesterId: requesterId,
            receiverId: receiverId,
            status: .pending
        )

        let docRef = db.collection("connections").document()
        var connectionWithId = connection
        connectionWithId.id = docRef.documentID

        try docRef.setData(from: connectionWithId)
    }

    func acceptConnection(_ connection: Connection) async throws {
        guard let connectionId = connection.id else { return }

        try await db.collection("connections").document(connectionId).updateData([
            "status": ConnectionStatus.accepted.rawValue,
            "acceptedAt": Timestamp(date: Date())
        ])

        await fetchConnections(for: connection.receiverId)
    }

    func ignoreConnection(_ connection: Connection) async throws {
        guard let connectionId = connection.id else { return }

        try await db.collection("connections").document(connectionId).updateData([
            "status": ConnectionStatus.ignored.rawValue
        ])

        await fetchPendingRequests(for: connection.receiverId)
    }

    func removeConnection(_ connection: Connection) async throws {
        guard let connectionId = connection.id else { return }
        try await db.collection("connections").document(connectionId).delete()
    }

    // MARK: - Fetching

    func fetchConnections(for userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch where user is requester
            let requesterSnapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.accepted.rawValue)
                .getDocuments()

            // Fetch where user is receiver
            let receiverSnapshot = try await db.collection("connections")
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.accepted.rawValue)
                .getDocuments()

            let requesterConnections = requesterSnapshot.documents.compactMap { try? $0.data(as: Connection.self) }
            let receiverConnections = receiverSnapshot.documents.compactMap { try? $0.data(as: Connection.self) }

            connections = requesterConnections + receiverConnections

            // Build set of connected user IDs
            connectedUserIds = Set(connections.flatMap { conn in
                [conn.requesterId, conn.receiverId].filter { $0 != userId }
            })
        } catch {
            print("Error fetching connections: \(error.localizedDescription)")
        }
    }

    func fetchPendingRequests(for userId: String) async {
        do {
            let snapshot = try await db.collection("connections")
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.pending.rawValue)
                .getDocuments()

            pendingRequests = snapshot.documents.compactMap { try? $0.data(as: Connection.self) }
        } catch {
            print("Error fetching pending requests: \(error.localizedDescription)")
        }
    }

    // MARK: - Queries

    func isConnected(with userId: String) -> Bool {
        connectedUserIds.contains(userId)
    }

    func hasPendingRequest(to userId: String, from currentUserId: String) async -> Bool {
        do {
            let snapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: currentUserId)
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.pending.rawValue)
                .getDocuments()

            return !snapshot.documents.isEmpty
        } catch {
            return false
        }
    }

    func getConnectionStatus(with userId: String, currentUserId: String) async -> ConnectionStatus? {
        do {
            // Check if current user sent request
            let sentSnapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: currentUserId)
                .whereField("receiverId", isEqualTo: userId)
                .getDocuments()

            if let doc = sentSnapshot.documents.first,
               let connection = try? doc.data(as: Connection.self) {
                return connection.status
            }

            // Check if current user received request
            let receivedSnapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: userId)
                .whereField("receiverId", isEqualTo: currentUserId)
                .getDocuments()

            if let doc = receivedSnapshot.documents.first,
               let connection = try? doc.data(as: Connection.self) {
                return connection.status
            }

            return nil
        } catch {
            return nil
        }
    }
}
```

**Step 2: Commit**

```bash
git add Oceanna/Services/ConnectionService.swift
git commit -m "feat: add ConnectionService for managing user connections"
```

---

### Task 11: Update FirestoreService

**Files:**
- Modify: `Oceanna/Services/FirestoreService.swift`

**Step 1: Update FirestoreService for new models**

Replace contents:

```swift
import Foundation
import FirebaseFirestore

@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    // MARK: - Users

    func fetchUser(id: String) async throws -> User? {
        let document = try await db.collection("users").document(id).getDocument()
        return try document.data(as: User.self)
    }

    func fetchUsers(ids: [String]) async throws -> [User] {
        guard !ids.isEmpty else { return [] }

        // Firestore limits 'in' queries to 10 items
        var allUsers: [User] = []
        for chunk in ids.chunked(into: 10) {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
            allUsers.append(contentsOf: users)
        }
        return allUsers
    }

    func fetchApprovedUsers(excluding userId: String, limit: Int = 50) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("approvalStatus", isEqualTo: ApprovalStatus.approved.rawValue)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.id != userId }
    }

    func fetchHireableUsers(excluding userId: String, limit: Int = 50) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("approvalStatus", isEqualTo: ApprovalStatus.approved.rawValue)
            .whereField("isHireable", isEqualTo: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.id != userId }
    }

    // MARK: - Portfolio

    func fetchPortfolio(for userId: String) async throws -> [PortfolioItem] {
        let snapshot = try await db.collection("portfolios")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: PortfolioItem.self) }
    }

    func addPortfolioItem(_ item: PortfolioItem) async throws {
        let docRef = db.collection("portfolios").document()
        var itemWithId = item
        itemWithId.id = docRef.documentID
        try docRef.setData(from: itemWithId)
    }

    func deletePortfolioItem(id: String) async throws {
        try await db.collection("portfolios").document(id).delete()
    }

    // MARK: - Posts

    func fetchPosts(for userIds: [String], limit: Int = 50) async throws -> [FeedPost] {
        guard !userIds.isEmpty else { return [] }

        var allPosts: [FeedPost] = []
        for chunk in userIds.chunked(into: 10) {
            let snapshot = try await db.collection("posts")
                .whereField("authorId", in: chunk)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()

            let posts = snapshot.documents.compactMap { try? $0.data(as: FeedPost.self) }
            allPosts.append(contentsOf: posts)
        }

        return allPosts.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchOpportunities(limit: Int = 50) async throws -> [FeedPost] {
        let snapshot = try await db.collection("posts")
            .whereField("postType", isEqualTo: PostType.opportunity.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: FeedPost.self) }
    }

    func createPost(_ post: FeedPost) async throws -> FeedPost {
        let docRef = db.collection("posts").document()
        var postWithId = post
        postWithId.id = docRef.documentID
        try docRef.setData(from: postWithId)
        return postWithId
    }

    func expressInterest(postId: String, userId: String) async throws {
        try await db.collection("posts").document(postId).updateData([
            "interestedUserIds": FieldValue.arrayUnion([userId])
        ])
    }

    func applyToOpportunity(postId: String, userId: String) async throws {
        try await db.collection("posts").document(postId).updateData([
            "applicantIds": FieldValue.arrayUnion([userId])
        ])
    }

    // MARK: - Reviews

    func fetchReviews(for userId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("revieweeId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }

    func createReview(_ review: Review) async throws {
        let docRef = db.collection("reviews").document()
        var reviewWithId = review
        reviewWithId.id = docRef.documentID
        try docRef.setData(from: reviewWithId)
    }

    func hasReviewed(conversationId: String, reviewerId: String) async throws -> Bool {
        let snapshot = try await db.collection("reviews")
            .whereField("conversationId", isEqualTo: conversationId)
            .whereField("reviewerId", isEqualTo: reviewerId)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

**Step 2: Commit**

```bash
git add Oceanna/Services/FirestoreService.swift
git commit -m "feat: update FirestoreService for new data models"
```

---

### Task 12: Delete Obsolete Services

**Files:**
- Delete: `Oceanna/Services/LocationService.swift`
- Delete: `Oceanna/Services/MatchingService.swift`

**Step 1: Remove obsolete files**

```bash
rm Oceanna/Services/LocationService.swift
rm Oceanna/Services/MatchingService.swift
```

**Step 2: Commit**

```bash
git add -A
git commit -m "chore: remove obsolete services (LocationService, MatchingService)"
```

---

## Phase 3: Navigation & Core Views

### Task 13: Update MainTabView

**Files:**
- Modify: `Oceanna/Core/Navigation/MainTabView.swift`

**Step 1: Update MainTabView with new design**

Replace contents:

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .feed
    @StateObject private var connectionService = ConnectionService.shared
    @EnvironmentObject var authService: AuthService

    enum Tab: String, CaseIterable {
        case feed = "Feed"
        case discover = "Discover"
        case messages = "Messages"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .feed: return "square.stack"
            case .discover: return "sparkle.magnifyingglass"
            case .messages: return "bubble.left.and.bubble.right"
            case .profile: return "person"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label(Tab.feed.rawValue, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)

            DiscoverView()
                .tabItem {
                    Label(Tab.discover.rawValue, systemImage: Tab.discover.icon)
                }
                .tag(Tab.discover)

            MessagesListView()
                .tabItem {
                    Label(Tab.messages.rawValue, systemImage: Tab.messages.icon)
                }
                .tag(Tab.messages)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(OceannaTheme.Colors.primary)
        .onAppear {
            setupTabBarAppearance()
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
}
```

**Step 2: Commit**

```bash
git add Oceanna/Core/Navigation/MainTabView.swift
git commit -m "feat: update MainTabView with new tab order and monochrome design"
```

---

### Task 14: Update ContentView for Approval Flow

**Files:**
- Modify: `Oceanna/App/ContentView.swift`

**Step 1: Update ContentView with approval states**

Replace contents:

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.currentUser == nil {
                AuthenticationView()
            } else if let user = authService.userProfile {
                switch user.approvalStatus {
                case .approved:
                    MainTabView()
                case .pending:
                    PendingApprovalView()
                case .waitlisted:
                    WaitlistView()
                }
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
```

**Step 2: Commit**

```bash
git add Oceanna/App/ContentView.swift
git commit -m "feat: update ContentView with approval flow routing"
```

---

This plan continues with Tasks 15-40+ covering:
- Phase 4: Onboarding Views (PendingApprovalView, WaitlistView, OnboardingView)
- Phase 5: Profile Views (ProfileView, EditProfileView, ExpandedProfileView)
- Phase 6: Feed Views (FeedView, CreatePostView, OpportunityDetailView)
- Phase 7: Discovery Views (DiscoverView, SwipeCardView, ApplicantStackView)
- Phase 8: Messages Views (MessagesListView, ChatView, QuoteView)
- Phase 9: Components (FramedImageCard, SkillTag, etc.)

---

**Plan complete and saved to `docs/plans/2026-01-17-oceanna-implementation.md`.**

**Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
