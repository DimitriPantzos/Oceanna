import SwiftUI

struct RatingView: View {
    let rating: Double
    let maxRating: Int = 5
    var size: CGFloat = 16
    var color: Color = .orange

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .font(.system(size: size))
                    .foregroundColor(color)
            }
        }
    }

    private func starType(for index: Int) -> String {
        let threshold = Double(index) + 0.5

        if rating >= Double(index + 1) {
            return "star.fill"
        } else if rating >= threshold {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct EditableRatingView: View {
    @Binding var rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 32
    var color: Color = .orange

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(color)
                    .onTapGesture {
                        rating = Double(index)
                    }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingView(rating: 4.5)
        RatingView(rating: 3.0, size: 24, color: .yellow)
        RatingView(rating: 5.0, size: 12)

        EditableRatingView(rating: .constant(3))
    }
    .padding()
}
