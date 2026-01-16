import SwiftUI

struct AvatarView: View {
    let user: User?
    var size: CGFloat = 50

    var body: some View {
        if let avatarUrl = user?.avatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Text(user?.initials ?? "?")
                    .font(.system(size: size * 0.4))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            )
    }
}

struct AvatarGroupView: View {
    let users: [User]
    var maxDisplay: Int = 3
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(Array(users.prefix(maxDisplay).enumerated()), id: \.element.id) { index, user in
                AvatarView(user: user, size: size)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
                    .zIndex(Double(maxDisplay - index))
            }

            if users.count > maxDisplay {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Text("+\(users.count - maxDisplay)")
                            .font(.system(size: size * 0.35))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(user: .example)
        AvatarView(user: .example, size: 80)
        AvatarView(user: nil, size: 60)

        AvatarGroupView(users: [.example, .example, .example, .example, .example])
    }
    .padding()
}
