import SwiftUI

struct AvatarView: View {
    let url: String?
    let initials: String
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(OceannaTheme.Colors.border, lineWidth: 1)
        )
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(OceannaTheme.Colors.secondaryBackground)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(OceannaTheme.Colors.tertiaryText)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(url: nil, initials: "SC", size: 100)
        AvatarView(url: nil, initials: "JD", size: 50)
    }
}
