import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isShowingSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var userType: UserType = .freelancer

    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        !displayName.isEmpty
    }

    var passwordsMatch: Bool {
        password == confirmPassword || confirmPassword.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("I am a...")
                        .font(.headline)

                    HStack(spacing: 12) {
                        UserTypeButton(
                            title: "Freelancer",
                            subtitle: "Offer my services",
                            icon: "person.fill",
                            isSelected: userType == .freelancer
                        ) {
                            userType = .freelancer
                        }

                        UserTypeButton(
                            title: "Client",
                            subtitle: "Hire talent",
                            icon: "briefcase.fill",
                            isSelected: userType == .client
                        ) {
                            userType = .client
                        }
                    }
                }
                .padding(.horizontal)

                // Form Fields
                VStack(spacing: 16) {
                    TextField("Full Name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)

                        if !passwordsMatch {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)

                // Sign Up Button
                Button {
                    Task {
                        await authViewModel.signUp(
                            email: email,
                            password: password,
                            displayName: displayName,
                            userType: userType
                        )
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                    }
                }
                .primaryButtonStyle()
                .padding(.horizontal)
                .disabled(!isFormValid || authViewModel.isLoading)

                // Terms
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider()
                    .padding(.vertical)

                // Switch to Sign In
                VStack(spacing: 12) {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)

                    Button("Sign In") {
                        withAnimation {
                            isShowingSignUp = false
                        }
                    }
                    .font(.headline)
                }
            }
            .padding(.vertical)
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct UserTypeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    SignUpView(isShowingSignUp: .constant(true))
        .environmentObject(AuthViewModel())
}
