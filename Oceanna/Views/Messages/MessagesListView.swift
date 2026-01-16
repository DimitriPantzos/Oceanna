import SwiftUI

struct MessagesListView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatView(conversation: conversation, viewModel: viewModel)) {
                        ConversationRow(
                            conversation: conversation,
                            otherUser: viewModel.getOtherParticipant(in: conversation),
                            unreadCount: viewModel.getUnreadCount(for: conversation)
                        )
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let conversation = viewModel.conversations[index]
                        Task {
                            await viewModel.archiveConversation(conversation)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // New message
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .overlay {
                if viewModel.conversations.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Messages",
                        systemImage: "message",
                        description: Text("Start a conversation by connecting with freelancers")
                    )
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    viewModel.startListening(for: userId)
                    await viewModel.loadConversationUsers()
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let otherUser: User?
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = otherUser?.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUser?.displayName ?? "User")
                        .font(.headline)
                        .lineLimit(1)

                    if let user = otherUser, user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    if let timestamp = conversation.lastMessageTimestamp {
                        Text(formatTimestamp(timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text(conversation.lastMessage ?? "No messages yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Spacer()

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 56, height: 56)
            .overlay(
                Text(otherUser?.initials ?? "?")
                    .font(.headline)
                    .foregroundColor(.blue)
            )
    }

    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    MessagesListView()
        .environmentObject(AuthViewModel())
}
