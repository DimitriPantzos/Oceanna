import SwiftUI

struct PortfolioCard: View {
    let item: PortfolioItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Framed image
            ZStack {
                OceannaTheme.Colors.background

                AsyncImage(url: URL(string: item.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(OceannaTheme.Colors.secondaryBackground)
                }
                .frame(width: 200 - OceannaTheme.Card.imagePadding * 2, height: 150)
                .clipped()
            }
            .frame(width: 200, height: 150 + OceannaTheme.Card.imagePadding * 2)

            // Info
            VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xxs) {
                Text(item.title)
                    .font(OceannaTheme.Typography.headline)
                    .foregroundColor(OceannaTheme.Colors.primaryText)
                    .lineLimit(1)

                if !item.tags.isEmpty {
                    Text(item.tags.joined(separator: " · "))
                        .font(OceannaTheme.Typography.monoSmall)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(OceannaTheme.Spacing.sm)
        }
        .frame(width: 200)
        .background(OceannaTheme.Colors.background)
        .cornerRadius(OceannaTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: OceannaTheme.Radius.md)
                .stroke(OceannaTheme.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    PortfolioCard(item: PortfolioItem.example)
        .padding()
}
