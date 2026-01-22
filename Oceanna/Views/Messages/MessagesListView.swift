import SwiftUI

struct MessagesListView: View {
    @EnvironmentObject var authService: AuthService
    private let connectionService = ConnectionService.shared
    private let firestoreService = FirestoreService.shared

    @State private var conversations: [Conversation] = []
    @State private var participants: [String: User] = [:]
    @State private var isLoading = true
    @State private var selectedSection: MessageSection = .messages

    enum MessageSection: String, CaseIterable {
        case messages = "Messages"
        case requests = "Requests"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(MessageSection.allCases, id: \.self) { section in
                        HStack {
                            Text(section.rawValue)
                            if section == .requests && !connectionService.pendingRequests.isEmpty {
                                Text("\(connectionService.pendingRequests.count)")
                                    .font(OceannaTheme.Typography.monoSmall)
                            }
                        }
                        .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(OceannaTheme.Spacing.md)

                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    switch selectedSection {
                    case .messages:
                        messagesSection
                    case .requests:
                        requestsSection
                    }
                }
            }
            .background(OceannaTheme.Colors.background)
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    private var messagesSection: some View {
        Group {
            if conversations.isEmpty {
                VStack(spacing: OceannaTheme.Spacing.md) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(OceannaTheme.Colors.tertiaryText)

                    Text("No messages yet")
                        .font(OceannaTheme.Typography.headline)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    Text("Connect with people to start chatting")
                        .font(OceannaTheme.Typography.subheadline)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(conversations) { conversation in
                        if let currentUserId = authService.userProfile?.id,
                           let otherUserId = conversation.otherParticipantId(currentUserId: currentUserId),
                           let otherUser = participants[otherUserId] {
                            NavigationLink {
                                ChatView(conversation: conversation, otherUser: otherUser)
                            } label: {
                                ConversationRow(
                                    conversation: conversation,
                                    otherUser: otherUser,
                                    currentUserId: currentUserId
                                )
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var requestsSection: some View {
        Group {
            if connectionService.pendingRequests.isEmpty {
                VStack(spacing: OceannaTheme.Spacing.md) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(OceannaTheme.Colors.tertiaryText)

                    Text("No pending requests")
                        .font(OceannaTheme.Typography.headline)
                        .foregroundColor(OceannaTheme.Colors.primaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(connectionService.pendingRequests) { request in
                        if let requester = participants[request.requesterId] {
                            ConnectionRequestRow(
                                request: request,
                                requester: requester,
                                onAccept: { acceptRequest(request) },
                                onIgnore: { ignoreRequest(request) }
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func loadData() async {
        guard let userId = authService.userProfile?.id else { return }

        // Load connections and pending requests
        await connectionService.fetchConnections(for: userId)
        await connectionService.fetchPendingRequests(for: userId)

        // TODO: Load conversations from Firestore
        // For now, conversations will be empty until messaging service is implemented

        // Fetch all participant users
        var allUserIds = Set(connectionService.pendingRequests.map { $0.requesterId })
        allUserIds.formUnion(connectionService.connectedUserIds)

        if !allUserIds.isEmpty {
            do {
                let users = try await firestoreService.fetchUsers(ids: Array(allUserIds))
                participants = Dictionary(uniqueKeysWithValues: users.compactMap { user in
                    guard let id = user.id else { return nil }
                    return (id, user)
                })
            } catch {
                print("Error loading participants: \(error)")
            }
        }

        isLoading = false
    }

    private func acceptRequest(_ request: Connection) {
        Task {
            try? await connectionService.acceptConnection(request)
            await loadData()
        }
    }

    private func ignoreRequest(_ request: Connection) {
        Task {
            try? await connectionService.ignoreConnection(request)
            await loadData()
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let otherUser: User
    let currentUserId: String

    var body: some View {
        HStack(spacing: OceannaTheme.Spacing.sm) {
            AvatarView(url: otherUser.avatarUrl, initials: otherUser.initials, size: 50)

            VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xxs) {
                HStack {
                    Text(otherUser.displayName)
                        .font(OceannaTheme.Typography.headline)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    Spacer()

                    if let lastMessageAt = conversation.lastMessageAt {
                        Text(lastMessageAt, style: .relative)
                            .font(OceannaTheme.Typography.caption)
                            .foregroundColor(OceannaTheme.Colors.tertiaryText)
                    }
                }

                HStack {
                    Text(conversation.lastMessage ?? "Start a conversation")
                        .font(OceannaTheme.Typography.subheadline)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                        .lineLimit(1)

                    Spacer()

                    if conversation.unreadCount(for: currentUserId) > 0 {
                        Text("\(conversation.unreadCount(for: currentUserId))")
                            .font(OceannaTheme.Typography.monoSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, OceannaTheme.Spacing.xs)
                            .padding(.vertical, OceannaTheme.Spacing.xxs)
                            .background(OceannaTheme.Colors.primary)
                            .cornerRadius(OceannaTheme.Radius.full)
                    }
                }
            }
        }
        .padding(.vertical, OceannaTheme.Spacing.xs)
    }
}

struct ConnectionRequestRow: View {
    let request: Connection
    let requester: User
    let onAccept: () -> Void
    let onIgnore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
            HStack(spacing: OceannaTheme.Spacing.sm) {
                AvatarView(url: requester.avatarUrl, initials: requester.initials, size: 50)

                VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xxs) {
                    Text(requester.displayName)
                        .font(OceannaTheme.Typography.headline)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    if let skill = requester.topSkill {
                        Text(skill)
                            .font(OceannaTheme.Typography.mono)
                            .foregroundColor(OceannaTheme.Colors.secondaryText)
                    }

                    if !requester.city.isEmpty {
                        Text(requester.city)
                            .font(OceannaTheme.Typography.caption)
                            .foregroundColor(OceannaTheme.Colors.tertiaryText)
                    }
                }

                Spacer()
            }

            HStack(spacing: OceannaTheme.Spacing.md) {
                Button("Ignore") {
                    onIgnore()
                }
                .oceannaButton(isPrimary: false)

                Button("Accept") {
                    onAccept()
                }
                .oceannaButton(isPrimary: true)
            }
        }
        .padding(.vertical, OceannaTheme.Spacing.sm)
    }
}

#Preview {
    MessagesListView()
        .environmentObject(AuthService.shared)
}
