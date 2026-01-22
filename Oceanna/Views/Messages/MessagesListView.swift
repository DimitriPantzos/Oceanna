import SwiftUI

struct MessagesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MessagesViewModel()

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
                            if section == .requests && !viewModel.connectionRequests.isEmpty {
                                Text("\(viewModel.connectionRequests.count)")
                                    .font(OceannaTheme.Typography.monoSmall)
                            }
                        }
                        .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(OceannaTheme.Spacing.md)

                // Content
                if viewModel.isLoading {
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
            .onAppear {
                if let userId = authViewModel.userProfile?.id {
                    viewModel.startListening(for: userId)
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .refreshable {
                if let userId = authViewModel.userProfile?.id {
                    await viewModel.refreshData(for: userId)
                }
            }
        }
    }

    private var messagesSection: some View {
        Group {
            if viewModel.conversations.isEmpty {
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
                    ForEach(viewModel.conversations) { conversation in
                        if let currentUserId = authViewModel.userProfile?.id,
                           let otherUserId = conversation.otherParticipantId(currentUserId: currentUserId),
                           let otherUser = viewModel.participantProfiles[otherUserId] {
                            NavigationLink {
                                ChatView(conversation: conversation, otherUser: otherUser, currentUserId: currentUserId)
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
            if viewModel.connectionRequests.isEmpty {
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
                    ForEach(viewModel.connectionRequests) { request in
                        if let requester = viewModel.participantProfiles[request.requesterId] {
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

    private func acceptRequest(_ request: Connection) {
        guard let userId = authViewModel.userProfile?.id else { return }
        Task {
            await viewModel.acceptConnection(request, currentUserId: userId)
        }
    }

    private func ignoreRequest(_ request: Connection) {
        guard let userId = authViewModel.userProfile?.id else { return }
        Task {
            await viewModel.declineConnection(request, currentUserId: userId)
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

                    if let lastMessageTimestamp = conversation.lastMessageTimestamp {
                        Text(lastMessageTimestamp, style: .relative)
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

                    if conversation.unreadCountFor(currentUserId) > 0 {
                        Text("\(conversation.unreadCountFor(currentUserId))")
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
        .environmentObject(AuthViewModel())
}
