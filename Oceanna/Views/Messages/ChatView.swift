import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    let otherUser: User

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    @State private var showingQuoteSheet = false
    @State private var showingCompletionAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: OceannaTheme.Spacing.sm) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authViewModel.userProfile?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(OceannaTheme.Spacing.md)
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastId = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            VStack(spacing: OceannaTheme.Spacing.sm) {
                // Project tools
                if !conversation.isCompleted {
                    HStack(spacing: OceannaTheme.Spacing.md) {
                        Button {
                            showingQuoteSheet = true
                        } label: {
                            Label("Quote", systemImage: "dollarsign.circle")
                                .font(OceannaTheme.Typography.mono)
                        }

                        Button {
                            showingCompletionAlert = true
                        } label: {
                            Label("Complete", systemImage: "checkmark.circle")
                                .font(OceannaTheme.Typography.mono)
                        }

                        Spacer()
                    }
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
                    .padding(.horizontal, OceannaTheme.Spacing.md)
                }

                // Text input
                HStack(spacing: OceannaTheme.Spacing.sm) {
                    TextField("Message", text: $newMessage, axis: .vertical)
                        .textFieldStyle(OceannaTextFieldStyle())
                        .lineLimit(1...4)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(newMessage.isEmpty ? OceannaTheme.Colors.tertiaryText : OceannaTheme.Colors.primary)
                    }
                    .disabled(newMessage.isEmpty)
                }
                .padding(.horizontal, OceannaTheme.Spacing.md)
                .padding(.bottom, OceannaTheme.Spacing.sm)
            }
        }
        .background(OceannaTheme.Colors.background)
        .navigationTitle(otherUser.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    // Profile view for other user
                    ExpandedProfileView(user: otherUser)
                } label: {
                    AvatarView(url: otherUser.avatarUrl, initials: otherUser.initials, size: 32)
                }
            }
        }
        .sheet(isPresented: $showingQuoteSheet) {
            SendQuoteSheet(conversationId: conversation.id ?? "", onSend: { quote in
                sendQuote(quote)
            })
        }
        .alert("Mark as Complete", isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                markComplete()
            }
        } message: {
            Text("This will mark the project as complete. Both parties must confirm before reviews can be left.")
        }
        .task {
            await loadMessages()
        }
    }

    private func loadMessages() async {
        // TODO: Implement message loading from Firestore
        // For now, show empty state
        isLoading = false
    }

    private func sendMessage() {
        guard !newMessage.isEmpty,
              let conversationId = conversation.id,
              let senderId = authViewModel.userProfile?.id else { return }

        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            content: newMessage
        )

        // Add to local list immediately for responsiveness
        messages.append(message)
        newMessage = ""

        // TODO: Save to Firestore
    }

    private func sendQuote(_ quote: QuoteData) {
        guard let conversationId = conversation.id,
              let senderId = authViewModel.userProfile?.id else { return }

        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            content: "Sent a quote",
            messageType: .quote,
            quoteData: quote
        )

        messages.append(message)
        // TODO: Save to Firestore
    }

    private func markComplete() {
        // TODO: Implement completion confirmation
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: OceannaTheme.Spacing.xxs) {
                switch message.messageType {
                case .text, .image:
                    Text(message.content)
                        .font(OceannaTheme.Typography.body)
                        .foregroundColor(isFromCurrentUser ? .white : OceannaTheme.Colors.primaryText)
                        .padding(OceannaTheme.Spacing.sm)
                        .background(isFromCurrentUser ? OceannaTheme.Colors.primary : OceannaTheme.Colors.secondaryBackground)
                        .cornerRadius(OceannaTheme.Radius.md)

                case .quote:
                    if let quote = message.quoteData {
                        QuoteBubble(quote: quote, isFromCurrentUser: isFromCurrentUser)
                    }

                case .milestone:
                    if let milestone = message.milestoneData {
                        MilestoneBubble(milestone: milestone, isFromCurrentUser: isFromCurrentUser)
                    }

                case .proposal, .completion:
                    Text(message.content)
                        .font(OceannaTheme.Typography.body)
                        .foregroundColor(OceannaTheme.Colors.primaryText)
                        .padding(OceannaTheme.Spacing.sm)
                        .background(OceannaTheme.Colors.secondaryBackground)
                        .cornerRadius(OceannaTheme.Radius.md)
                }

                Text(message.createdAt, style: .time)
                    .font(OceannaTheme.Typography.caption)
                    .foregroundColor(OceannaTheme.Colors.tertiaryText)
            }

            if !isFromCurrentUser { Spacer() }
        }
    }
}

struct QuoteBubble: View {
    let quote: QuoteData
    let isFromCurrentUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xs) {
            HStack {
                Image(systemName: "dollarsign.circle")
                Text("Quote")
                    .font(OceannaTheme.Typography.mono)
            }
            .foregroundColor(OceannaTheme.Colors.secondaryText)

            Text(quote.description)
                .font(OceannaTheme.Typography.body)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            Text(quote.amount)
                .font(OceannaTheme.Typography.title3)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            if let validUntil = quote.validUntil {
                Text("Valid until \(validUntil, style: .date)")
                    .font(OceannaTheme.Typography.caption)
                    .foregroundColor(OceannaTheme.Colors.tertiaryText)
            }
        }
        .padding(OceannaTheme.Spacing.md)
        .background(OceannaTheme.Colors.secondaryBackground)
        .cornerRadius(OceannaTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: OceannaTheme.Radius.md)
                .stroke(OceannaTheme.Colors.border, lineWidth: 1)
        )
    }
}

struct MilestoneBubble: View {
    let milestone: MilestoneData
    let isFromCurrentUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xs) {
            HStack {
                Image(systemName: milestone.status == .completed ? "checkmark.circle.fill" : "circle")
                Text("Milestone")
                    .font(OceannaTheme.Typography.mono)
            }
            .foregroundColor(milestone.status == .completed ? .green : OceannaTheme.Colors.secondaryText)

            Text(milestone.title)
                .font(OceannaTheme.Typography.body)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            if let amount = milestone.amount {
                Text(amount)
                    .font(OceannaTheme.Typography.headline)
                    .foregroundColor(OceannaTheme.Colors.primaryText)
            }
        }
        .padding(OceannaTheme.Spacing.md)
        .background(OceannaTheme.Colors.secondaryBackground)
        .cornerRadius(OceannaTheme.Radius.md)
    }
}

struct SendQuoteSheet: View {
    let conversationId: String
    let onSend: (QuoteData) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var amount = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: OceannaTheme.Spacing.lg) {
                TextField("Description", text: $description, axis: .vertical)
                    .textFieldStyle(OceannaTextFieldStyle())
                    .lineLimit(2...4)

                TextField("Amount (e.g., $1,500)", text: $amount)
                    .textFieldStyle(OceannaTextFieldStyle())

                Spacer()
            }
            .padding(OceannaTheme.Spacing.lg)
            .navigationTitle("Send Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        let quote = QuoteData(description: description, amount: amount)
                        onSend(quote)
                        dismiss()
                    }
                    .disabled(description.isEmpty || amount.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ExpandedProfileView: View {
    let user: User
    private let firestoreService = FirestoreService.shared
    @State private var portfolio: [PortfolioItem] = []
    @State private var reviews: [Review] = []

    var body: some View {
        ScrollView {
            VStack(spacing: OceannaTheme.Spacing.lg) {
                // Header
                VStack(spacing: OceannaTheme.Spacing.md) {
                    AvatarView(url: user.avatarUrl, initials: user.initials, size: 100)

                    VStack(spacing: OceannaTheme.Spacing.xxs) {
                        Text(user.displayName)
                            .font(OceannaTheme.Typography.title2)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        if !user.city.isEmpty {
                            Text(user.availabilityBadge)
                                .font(OceannaTheme.Typography.mono)
                                .foregroundColor(OceannaTheme.Colors.secondaryText)
                        }
                    }

                    if let bio = user.bio {
                        Text(bio)
                            .font(OceannaTheme.Typography.body)
                            .foregroundColor(OceannaTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, OceannaTheme.Spacing.xl)
                    }
                }
                .padding(.top, OceannaTheme.Spacing.lg)

                // Skills
                if !user.skills.isEmpty {
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
                        Text("Skills")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                            ForEach(user.skills, id: \.self) { skill in
                                Text(skill)
                                    .monoTag()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, OceannaTheme.Spacing.lg)
                }

                // Portfolio
                if !portfolio.isEmpty {
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
                        Text("Portfolio")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)
                            .padding(.horizontal, OceannaTheme.Spacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: OceannaTheme.Spacing.md) {
                                ForEach(portfolio) { item in
                                    PortfolioCard(item: item)
                                }
                            }
                            .padding(.horizontal, OceannaTheme.Spacing.lg)
                        }
                    }
                }

                // Reviews
                if !reviews.isEmpty {
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
                        Text("Reviews")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        ForEach(reviews) { review in
                            ReviewCard(review: review)
                        }
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)
                }
            }
            .padding(.bottom, OceannaTheme.Spacing.xxl)
        }
        .background(OceannaTheme.Colors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        guard let userId = user.id else { return }

        do {
            portfolio = try await firestoreService.fetchPortfolio(for: userId)
            reviews = try await firestoreService.fetchReviews(for: userId)
        } catch {
            print("Error loading profile data: \(error)")
        }
    }
}

#Preview {
    ChatView(
        conversation: Conversation.example,
        otherUser: User.example
    )
    .environmentObject(AuthViewModel())
}
