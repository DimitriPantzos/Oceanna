import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: OceannaTheme.Spacing.xl) {
                VStack(spacing: OceannaTheme.Spacing.sm) {
                    Text("Create Account")
                        .font(OceannaTheme.Typography.title)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    Text("Join the creative community")
                        .font(OceannaTheme.Typography.subheadline)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                }
                .padding(.top, OceannaTheme.Spacing.xl)

                VStack(spacing: OceannaTheme.Spacing.md) {
                    TextField("Full Name", text: $displayName)
                        .textFieldStyle(OceannaTextFieldStyle())
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Email", text: $email)
                        .textFieldStyle(OceannaTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(OceannaTextFieldStyle())
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, OceannaTheme.Spacing.lg)

                if let error = errorMessage {
                    Text(error)
                        .font(OceannaTheme.Typography.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, OceannaTheme.Spacing.lg)
                }

                Button {
                    signUp()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .oceannaButton(isPrimary: true)
                .disabled(isLoading || !isValid)
                .padding(.horizontal, OceannaTheme.Spacing.lg)

                Spacer()
            }
        }
        .background(OceannaTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && !displayName.isEmpty && password.count >= 6
    }

    private func signUp() {
        isLoading = true
        errorMessage = nil

        Task {
            await authViewModel.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            errorMessage = authViewModel.errorMessage
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
