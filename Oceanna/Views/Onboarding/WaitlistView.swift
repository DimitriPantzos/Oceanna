import SwiftUI

struct WaitlistView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: OceannaTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "person.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(OceannaTheme.Colors.primary)

            VStack(spacing: OceannaTheme.Spacing.sm) {
                Text("On the Waitlist")
                    .font(OceannaTheme.Typography.title)
                    .foregroundColor(OceannaTheme.Colors.primaryText)

                Text("Your profile needs a bit more work before we can approve it. Here's what you can do:")
                    .font(OceannaTheme.Typography.body)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, OceannaTheme.Spacing.lg)
            }

            VStack(alignment: .leading, spacing: OceannaTheme.Spacing.md) {
                WaitlistTip(icon: "photo", text: "Add a professional profile photo")
                WaitlistTip(icon: "briefcase", text: "Add at least 3 skills")
                WaitlistTip(icon: "text.alignleft", text: "Write a compelling bio")
                WaitlistTip(icon: "photo.on.rectangle", text: "Upload portfolio work")
            }
            .padding(.horizontal, OceannaTheme.Spacing.xl)

            Spacer()

            Button("Update Profile") {
                // Navigate to edit profile
            }
            .oceannaButton(isPrimary: true)

            Button("Sign Out") {
                authViewModel.signOut()
            }
            .font(OceannaTheme.Typography.subheadline)
            .foregroundColor(OceannaTheme.Colors.secondaryText)

            Spacer().frame(height: OceannaTheme.Spacing.xxl)
        }
        .background(OceannaTheme.Colors.background)
    }
}

struct WaitlistTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: OceannaTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(OceannaTheme.Colors.primary)
                .frame(width: 24)

            Text(text)
                .font(OceannaTheme.Typography.subheadline)
                .foregroundColor(OceannaTheme.Colors.primaryText)
        }
    }
}

#Preview {
    WaitlistView()
        .environmentObject(AuthViewModel())
}
