# Oceanna Architecture Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix critical build issues and refactor Oceanna to use proper SwiftUI architecture patterns with ViewModels, consistent models, and secure Firestore rules.

**Architecture:** Introduce MVVM pattern with ViewModels between Views and Services. Align all model definitions with their service counterparts. Replace singleton `@StateObject` usage with proper dependency injection via `@EnvironmentObject`.

**Tech Stack:** SwiftUI, Firebase (Auth, Firestore, Storage), MVVM architecture

---

## Phase 1: Critical Fixes (Build Blocking)

### Task 1.1: Create AuthViewModel

**Files:**
- Create: `Oceanna/Oceanna/ViewModels/AuthViewModel.swift`

**Step 1: Create the ViewModels directory and AuthViewModel file**

```swift
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    private let authService = AuthService.shared

    @Published var isAuthenticated = false
    @Published var isApproved = false
    @Published var isPending = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userProfile: User?

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
}
```

**Step 2: Verify the project builds**

Run: Open Xcode and build (Cmd+B)
Expected: Build succeeds with AuthViewModel resolved

**Step 3: Commit**

```bash
git add Oceanna/Oceanna/ViewModels/AuthViewModel.swift
git commit -m "feat: add AuthViewModel to fix build error"
```

---

### Task 1.2: Align Message Model with MessagingService

The `Message` model and `MessagingService` use different field names. Align them.

**Files:**
- Modify: `Oceanna/Oceanna/Models/Message.swift`
- Modify: `Oceanna/Oceanna/Services/MessagingService.swift`

**Step 1: Review current mismatches**

| Model Field | Service Expects | Action |
|-------------|-----------------|--------|
| `createdAt` | `timestamp` | Rename to `timestamp` |
| `attachments: [String]` | `attachments: [Attachment]` | Keep as `[String]` (URLs) |
| N/A | `isRead` | Add to model |

**Step 2: Update Message model**

In `Oceanna/Oceanna/Models/Message.swift`, change:

```swift
// Change this line:
var createdAt: Date

// To:
var timestamp: Date

// Add after attachments:
var isRead: Bool
```

Update the init:
```swift
init(
    id: String? = nil,
    conversationId: String,
    senderId: String,
    content: String,
    messageType: MessageType = .text,
    attachments: [String] = [],
    quoteData: QuoteData? = nil,
    milestoneData: MilestoneData? = nil,
    timestamp: Date = Date(),
    isRead: Bool = false
) {
    self.id = id
    self.conversationId = conversationId
    self.senderId = senderId
    self.content = content
    self.messageType = messageType
    self.attachments = attachments
    self.quoteData = quoteData
    self.milestoneData = milestoneData
    self.timestamp = timestamp
    self.isRead = isRead
}
```

Update static examples:
```swift
extension Message {
    static let example = Message(
        id: "msg1",
        conversationId: "conv1",
        senderId: "user1",
        content: "Hey! I'd love to work on this project with you.",
        timestamp: Date()
    )

    static let quoteExample = Message(
        id: "msg2",
        conversationId: "conv1",
        senderId: "user1",
        content: "Here's my quote for the project:",
        messageType: .quote,
        quoteData: QuoteData(description: "Brand identity package", amount: "$1,500"),
        timestamp: Date()
    )
}
```

**Step 3: Update MessagingService sendMessage**

In `Oceanna/Oceanna/Services/MessagingService.swift`, change the `sendMessage` function:

```swift
func sendMessage(
    in conversationId: String,
    senderId: String,
    content: String,
    messageType: MessageType = .text,
    attachments: [String] = []
) async throws {
    let message = Message(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        messageType: messageType,
        attachments: attachments,
        timestamp: Date(),
        isRead: false
    )

    // ... rest unchanged
}
```

**Step 4: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: No errors related to Message type

**Step 5: Commit**

```bash
git add Oceanna/Oceanna/Models/Message.swift Oceanna/Oceanna/Services/MessagingService.swift
git commit -m "fix: align Message model fields with MessagingService expectations"
```

---

### Task 1.3: Align Conversation Model with MessagingService

**Files:**
- Modify: `Oceanna/Oceanna/Models/Message.swift` (Conversation struct)
- Modify: `Oceanna/Oceanna/Services/MessagingService.swift`

**Step 1: Review mismatches**

| Model Field | Service Expects | Action |
|-------------|-----------------|--------|
| `participantIds` | `participants` | Rename to `participants` |
| `lastMessageAt` | `lastMessageTimestamp` | Rename to `lastMessageTimestamp` |
| N/A | `isActive` | Add to model |
| `projectReference` | `projectId` | Rename to `projectId` |
| `unreadCounts` | `unreadCount` | Rename to `unreadCount` |

**Step 2: Update Conversation model**

```swift
struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String]
    var projectId: String?
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var unreadCount: [String: Int]
    var isActive: Bool
    var isCompleted: Bool
    var completionConfirmedBy: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        participants: [String],
        projectId: String? = nil,
        lastMessage: String? = nil,
        lastMessageTimestamp: Date? = nil,
        lastMessageSenderId: String? = nil,
        unreadCount: [String: Int] = [:],
        isActive: Bool = true,
        isCompleted: Bool = false,
        completionConfirmedBy: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participants = participants
        self.projectId = projectId
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCount = unreadCount
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.completionConfirmedBy = completionConfirmedBy
        self.createdAt = createdAt
    }

    func otherParticipantId(currentUserId: String) -> String? {
        participants.first { $0 != currentUserId }
    }

    func unreadCountFor(_ userId: String) -> Int {
        unreadCount[userId] ?? 0
    }

    var canLeaveReview: Bool {
        completionConfirmedBy.count == 2
    }
}

extension Conversation {
    static let example = Conversation(
        id: "conv1",
        participants: ["user1", "user2"],
        lastMessage: "Sounds great, let's do it!",
        lastMessageTimestamp: Date()
    )
}
```

**Step 3: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Oceanna/Oceanna/Models/Message.swift
git commit -m "fix: align Conversation model fields with MessagingService"
```

---

## Phase 2: High Priority Fixes

### Task 2.1: Move OceannaTextFieldStyle to OceannaTheme

**Files:**
- Modify: `Oceanna/Oceanna/Core/Design/OceannaTheme.swift`
- Modify: `Oceanna/Oceanna/Views/Onboarding/OnboardingView.swift`

**Step 1: Add OceannaTextFieldStyle to OceannaTheme.swift**

At the end of `OceannaTheme.swift`, before the closing brace of View extension, add:

```swift
struct OceannaTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(OceannaTheme.Typography.body)
            .padding(OceannaTheme.Spacing.md)
            .background(OceannaTheme.Colors.secondaryBackground)
            .cornerRadius(OceannaTheme.Radius.sm)
    }
}
```

**Step 2: Remove from OnboardingView.swift**

Delete lines 289-297 from `OnboardingView.swift` (the `OceannaTextFieldStyle` struct).

**Step 3: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: Build succeeds, no duplicate symbol errors

**Step 4: Commit**

```bash
git add Oceanna/Oceanna/Core/Design/OceannaTheme.swift Oceanna/Oceanna/Views/Onboarding/OnboardingView.swift
git commit -m "refactor: move OceannaTextFieldStyle to OceannaTheme"
```

---

### Task 2.2: Fix @StateObject Usage with Singletons

`@StateObject` should not be used with `.shared` singletons. Fix all occurrences.

**Files:**
- Modify: `Oceanna/Oceanna/Views/Discovery/DiscoveryView.swift`
- Modify: Any other views using this pattern

**Step 1: In DiscoveryView.swift, change:**

```swift
// From:
@StateObject private var firestoreService = FirestoreService.shared
@StateObject private var connectionService = ConnectionService.shared

// To:
private let firestoreService = FirestoreService.shared
private let connectionService = ConnectionService.shared
```

**Step 2: Search for other occurrences**

Run: `grep -r "@StateObject.*\.shared" Oceanna/Oceanna/Views/`

Apply the same fix to all matching files.

**Step 3: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add -A
git commit -m "fix: replace @StateObject with let for singleton services"
```

---

### Task 2.3: Update Views to Use AuthViewModel

**Files:**
- Modify: `Oceanna/Oceanna/Views/Onboarding/OnboardingView.swift`
- Modify: Other views using `AuthService` directly

**Step 1: In OnboardingView.swift, change:**

```swift
// From:
@EnvironmentObject var authService: AuthService

// To:
@EnvironmentObject var authViewModel: AuthViewModel
```

**Step 2: Update function calls**

```swift
// From:
try await authService.completeOnboarding(...)

// To:
await authViewModel.completeOnboarding(...)
```

**Step 3: Update ContentView to pass AuthViewModel**

Ensure `ContentView` uses `authViewModel` from environment.

**Step 4: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 5: Commit**

```bash
git add -A
git commit -m "refactor: update views to use AuthViewModel"
```

---

## Phase 3: ViewModel Layer (Medium Priority)

### Task 3.1: Create DiscoveryViewModel

**Files:**
- Create: `Oceanna/Oceanna/ViewModels/DiscoveryViewModel.swift`
- Modify: `Oceanna/Oceanna/Views/Discovery/DiscoveryView.swift`

**Step 1: Create DiscoveryViewModel**

```swift
import Foundation
import Combine

@MainActor
class DiscoveryViewModel: ObservableObject {
    private let firestoreService = FirestoreService.shared
    private let connectionService = ConnectionService.shared

    @Published var users: [User] = []
    @Published var opportunities: [FeedPost] = []
    @Published var opportunityAuthors: [String: User] = [:]
    @Published var currentIndex = 0
    @Published var isLoading = true
    @Published var errorMessage: String?

    func loadContent(for userId: String, isHireable: Bool) async {
        isLoading = true
        currentIndex = 0
        errorMessage = nil

        do {
            if isHireable {
                opportunities = try await firestoreService.fetchOpportunities()
                let authorIds = Set(opportunities.map { $0.authorId })
                let authors = try await firestoreService.fetchUsers(ids: Array(authorIds))
                opportunityAuthors = Dictionary(uniqueKeysWithValues: authors.compactMap { user in
                    guard let id = user.id else { return nil }
                    return (id, user)
                })
            } else {
                users = try await firestoreService.fetchHireableUsers(excluding: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func sendConnectionRequest(to targetUserId: String, from currentUserId: String) async {
        do {
            try await connectionService.sendConnectionRequest(to: targetUserId, from: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyToOpportunity(postId: String, userId: String) async {
        do {
            try await firestoreService.applyToOpportunity(postId: postId, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func nextCard() {
        currentIndex += 1
    }

    func refresh() {
        currentIndex = 0
    }
}
```

**Step 2: Update DiscoveryView to use ViewModel**

```swift
struct DiscoveryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = DiscoveryViewModel()

    // ... rest of view using viewModel instead of direct service calls
}
```

**Step 3: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Oceanna/Oceanna/ViewModels/DiscoveryViewModel.swift Oceanna/Oceanna/Views/Discovery/DiscoveryView.swift
git commit -m "refactor: extract DiscoveryViewModel from DiscoveryView"
```

---

### Task 3.2: Create MessagesViewModel

**Files:**
- Create: `Oceanna/Oceanna/ViewModels/MessagesViewModel.swift`
- Modify: `Oceanna/Oceanna/Views/Messages/MessagesListView.swift`

**Step 1: Create MessagesViewModel**

```swift
import Foundation
import Combine

@MainActor
class MessagesViewModel: ObservableObject {
    private let messagingService = MessagingService.shared
    private let firestoreService = FirestoreService.shared
    private let connectionService = ConnectionService.shared

    @Published var conversations: [Conversation] = []
    @Published var connectionRequests: [Connection] = []
    @Published var participantProfiles: [String: User] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        messagingService.$conversations
            .assign(to: &$conversations)
    }

    func startListening(for userId: String) {
        messagingService.listenToConversations(for: userId)

        Task {
            await loadConnectionRequests(for: userId)
        }
    }

    func stopListening() {
        messagingService.stopListeningToConversations()
    }

    func loadConnectionRequests(for userId: String) async {
        do {
            connectionRequests = try await connectionService.fetchPendingRequests(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadParticipantProfile(userId: String) async {
        guard participantProfiles[userId] == nil else { return }

        do {
            if let user = try await firestoreService.fetchUser(id: userId) {
                participantProfiles[userId] = user
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }

    func acceptConnection(_ connection: Connection, currentUserId: String) async {
        do {
            try await connectionService.acceptConnection(connection, currentUserId: currentUserId)
            await loadConnectionRequests(for: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineConnection(_ connection: Connection) async {
        do {
            try await connectionService.declineConnection(connection)
            connectionRequests.removeAll { $0.id == connection.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

**Step 2: Update MessagesListView**

Update to use `@StateObject private var viewModel = MessagesViewModel()` and delegate all logic.

**Step 3: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Oceanna/Oceanna/ViewModels/MessagesViewModel.swift Oceanna/Oceanna/Views/Messages/MessagesListView.swift
git commit -m "refactor: extract MessagesViewModel from MessagesListView"
```

---

### Task 3.3: Create ChatViewModel

**Files:**
- Create: `Oceanna/Oceanna/ViewModels/ChatViewModel.swift`
- Modify: `Oceanna/Oceanna/Views/Messages/ChatView.swift`

**Step 1: Create ChatViewModel**

```swift
import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    private let messagingService = MessagingService.shared

    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSending = false

    private var cancellables = Set<AnyCancellable>()

    let conversationId: String
    let currentUserId: String

    init(conversationId: String, currentUserId: String) {
        self.conversationId = conversationId
        self.currentUserId = currentUserId

        messagingService.$activeConversationMessages
            .assign(to: &$messages)
    }

    func startListening() {
        messagingService.listenToMessages(in: conversationId)

        Task {
            try? await messagingService.markMessagesAsRead(in: conversationId, for: currentUserId)
        }
    }

    func stopListening() {
        messagingService.stopListeningToMessages()
    }

    func sendMessage(content: String, type: MessageType = .text) async {
        guard !content.isEmpty else { return }

        isSending = true
        do {
            try await messagingService.sendMessage(
                in: conversationId,
                senderId: currentUserId,
                content: content,
                messageType: type
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func sendQuote(description: String, amount: String) async {
        // Implementation for quote messages
    }

    func sendMilestone(title: String, amount: String?) async {
        // Implementation for milestone messages
    }

    func setTyping(_ isTyping: Bool) async {
        try? await messagingService.setTypingStatus(
            in: conversationId,
            userId: currentUserId,
            isTyping: isTyping
        )
    }
}
```

**Step 2: Update ChatView**

Refactor to use `ChatViewModel` and remove TODO comments.

**Step 3: Build and verify**

Run: Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Oceanna/Oceanna/ViewModels/ChatViewModel.swift Oceanna/Oceanna/Views/Messages/ChatView.swift
git commit -m "refactor: extract ChatViewModel and implement messaging"
```

---

## Phase 4: Security (High Priority)

### Task 4.1: Document Firestore Security Rules

**Files:**
- Create: `Oceanna/firestore.rules`

**Step 1: Create secure Firestore rules file**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isParticipant(participants) {
      return request.auth.uid in participants;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }

    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isAuthenticated() && isParticipant(resource.data.participants);
      allow create: if isAuthenticated() && isParticipant(request.resource.data.participants);
      allow update: if isAuthenticated() && isParticipant(resource.data.participants);

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isAuthenticated() && isParticipant(get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants);
        allow create: if isAuthenticated() && request.auth.uid == request.resource.data.senderId;
      }
    }

    // Connections collection
    match /connections/{connectionId} {
      allow read: if isAuthenticated() && (
        resource.data.fromUserId == request.auth.uid ||
        resource.data.toUserId == request.auth.uid
      );
      allow create: if isAuthenticated() && request.resource.data.fromUserId == request.auth.uid;
      allow update: if isAuthenticated() && (
        resource.data.fromUserId == request.auth.uid ||
        resource.data.toUserId == request.auth.uid
      );
    }

    // Feed posts collection
    match /feedPosts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.authorId == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.authorId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.authorId == request.auth.uid;
    }
  }
}
```

**Step 2: Commit**

```bash
git add Oceanna/firestore.rules
git commit -m "feat: add secure Firestore rules with row-level security"
```

**Step 3: Deploy to Firebase (manual)**

```bash
cd Oceanna
firebase deploy --only firestore:rules
```

---

## Phase 5: Cleanup (Low Priority)

### Task 5.1: Remove Dead Code from View+Extensions

**Files:**
- Modify: `Oceanna/Oceanna/Core/Extensions/View+Extensions.swift`

**Step 1: Review and remove unused extensions**

Audit the file and remove any extensions not used elsewhere in the codebase.

**Step 2: Commit**

```bash
git add Oceanna/Oceanna/Core/Extensions/View+Extensions.swift
git commit -m "chore: remove unused view extensions"
```

---

## Summary

| Phase | Tasks | Priority | Estimated Steps |
|-------|-------|----------|-----------------|
| 1 | Critical Fixes (AuthViewModel, Model alignment) | CRITICAL | 15 |
| 2 | High Priority (TextField style, @StateObject fix) | HIGH | 10 |
| 3 | ViewModel Layer (Discovery, Messages, Chat) | MEDIUM | 20 |
| 4 | Security (Firestore rules) | HIGH | 5 |
| 5 | Cleanup (Dead code) | LOW | 3 |

**Total estimated steps:** ~53

---

## Execution Notes

1. **Build after each task** - Verify no regressions
2. **Commit frequently** - One commit per task minimum
3. **Test in Simulator** - Verify app flows still work
4. **Don't skip Phase 1** - Build is broken without it
