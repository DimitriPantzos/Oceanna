import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: OceannaTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "clock")
                .font(.system(size: 80))
                .foregroundColor(OceannaTheme.Colors.primary)

            VStack(spacing: OceannaTheme.Spacing.sm) {
                Text("Under Review")
                    .font(OceannaTheme.Typography.title)
                    .foregroundColor(OceannaTheme.Colors.primaryText)

                Text("Your profile is being reviewed by our team. We'll notify you once you're approved.")
                    .font(OceannaTheme.Typography.body)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, OceannaTheme.Spacing.xl)
            }

            Spacer()

            Button("Sign Out") {
                try? authService.signOut()
            }
            .font(OceannaTheme.Typography.subheadline)
            .foregroundColor(OceannaTheme.Colors.secondaryText)

            Spacer().frame(height: OceannaTheme.Spacing.xxl)
        }
        .background(OceannaTheme.Colors.background)
    }
}

#Preview {
    PendingApprovalView()
        .environmentObject(AuthService.shared)
}
