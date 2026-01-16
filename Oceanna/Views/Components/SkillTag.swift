import SwiftUI

struct SkillTag: View {
    let text: String
    var color: Color = .blue

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

#Preview {
    HStack {
        SkillTag(text: "Swift")
        SkillTag(text: "UI/UX Design", color: .purple)
        SkillTag(text: "Photography", color: .orange)
    }
    .padding()
}
