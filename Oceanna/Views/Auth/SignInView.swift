import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: OceannaTheme.Spacing.xl) {
                VStack(spacing: OceannaTheme.Spacing.sm) {
                    Text("Welcome Back")
                        .font(OceannaTheme.Typography.title)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    Text("Sign in to continue")
                        .font(OceannaTheme.Typography.subheadline)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                }
                .padding(.top, OceannaTheme.Spacing.xl)

                VStack(spacing: OceannaTheme.Spacing.md) {
                    TextField("Email", text: $email)
                        .textFieldStyle(OceannaTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(OceannaTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal, OceannaTheme.Spacing.lg)

                if let error = errorMessage {
                    Text(error)
                        .font(OceannaTheme.Typography.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, OceannaTheme.Spacing.lg)
                }

                Button {
                    signIn()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .oceannaButton(isPrimary: true)
                .disabled(isLoading || !isValid)
                .padding(.horizontal, OceannaTheme.Spacing.lg)

                Button("Forgot Password?") {
                    // TODO: Implement password reset
                }
                .font(OceannaTheme.Typography.subheadline)
                .foregroundColor(OceannaTheme.Colors.secondaryText)

                Spacer()
            }
        }
        .background(OceannaTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(AuthService.shared)
    }
}
