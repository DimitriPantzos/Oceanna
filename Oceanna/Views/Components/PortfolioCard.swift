import SwiftUI

struct PortfolioCard: View {
    let item: PortfolioItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let imageUrl = item.imageUrls.first, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                .frame(width: 200, height: 150)
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 200, height: 150)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }

            // Title
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            // Tags
            if !item.tags.isEmpty {
                HStack {
                    ForEach(item.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .frame(width: 200)
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack {
            PortfolioCard(item: PortfolioItem(
                title: "Brand Identity Project",
                description: "Complete branding for startup",
                imageUrls: [],
                createdAt: Date(),
                tags: ["branding", "logo"]
            ))

            PortfolioCard(item: PortfolioItem(
                title: "Mobile App Design",
                description: "UI/UX for iOS app",
                imageUrls: [],
                createdAt: Date(),
                tags: ["UI/UX", "mobile"]
            ))
        }
        .padding()
    }
}
