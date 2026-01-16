import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var viewModel: MessagesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var messageText = ""
    @State private var showAttachmentPicker = false
    @FocusState private var isInputFocused: Bool

    var otherUser: User? {
        viewModel.getOtherParticipant(in: conversation)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: viewModel.isFromCurrentUser(message)
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input area
            HStack(spacing: 12) {
                Button {
                    showAttachmentPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .onChange(of: messageText) { _, newValue in
                        if let conversationId = conversation.id {
                            viewModel.setTyping(in: conversationId, isTyping: !newValue.isEmpty)
                        }
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty || viewModel.isSending)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(otherUser?.displayName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    if let avatarUrl = otherUser?.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.blue.opacity(0.2))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(otherUser?.displayName ?? "User")
                            .font(.headline)
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("View Profile", systemImage: "person.circle") { }
                    Button("Block User", systemImage: "nosign", role: .destructive) { }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onAppear {
            viewModel.openConversation(conversation)
        }
        .onDisappear {
            viewModel.closeConversation()
            if let conversationId = conversation.id {
                viewModel.setTyping(in: conversationId, isTyping: false)
            }
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty, let conversationId = conversation.id else { return }

        let text = messageText
        messageText = ""

        Task {
            await viewModel.sendMessage(in: conversationId, content: text)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Attachments
                if !message.attachments.isEmpty {
                    ForEach(message.attachments) { attachment in
                        if attachment.type == .image, let url = URL(string: attachment.url) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(12)
                        }
                    }
                }

                // Text content
                if !message.content.isEmpty {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(isFromCurrentUser ? .white : .primary)
                        .cornerRadius(20)
                }

                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)

            if !isFromCurrentUser { Spacer() }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: .example, viewModel: MessagesViewModel())
            .environmentObject(AuthViewModel())
    }
}
