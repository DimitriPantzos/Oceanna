import SwiftUI

struct AuthenticationView: View {
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: OceannaTheme.Spacing.xl) {
                Spacer()

                // Logo/Brand
                VStack(spacing: OceannaTheme.Spacing.sm) {
                    Text("Oceanna")
                        .font(OceannaTheme.Typography.largeTitle)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    Text("Where talent meets talent")
                        .font(OceannaTheme.Typography.subheadline)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                }

                Spacer()

                // Actions
                VStack(spacing: OceannaTheme.Spacing.md) {
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                    }
                    .oceannaButton(isPrimary: true)

                    NavigationLink {
                        SignInView()
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                    .oceannaButton(isPrimary: false)
                }
                .padding(.horizontal, OceannaTheme.Spacing.lg)

                Spacer().frame(height: OceannaTheme.Spacing.xxxl)
            }
            .background(OceannaTheme.Colors.background)
        }
    }
}

#Preview {
    AuthenticationView()
}
