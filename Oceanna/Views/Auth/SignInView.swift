import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isShowingSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
            }
            .padding(.horizontal)

            Button {
                Task {
                    await authViewModel.signIn(email: email, password: password)
                }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                }
            }
            .primaryButtonStyle()
            .padding(.horizontal)
            .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.subheadline)

            Divider()
                .padding(.vertical)

            VStack(spacing: 12) {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)

                Button("Create Account") {
                    withAnimation {
                        isShowingSignUp = true
                    }
                }
                .font(.headline)
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                Button("Send Reset Link") {
                    Task {
                        await authViewModel.resetPassword(email: email)
                        showConfirmation = true
                    }
                }
                .primaryButtonStyle()
                .padding(.horizontal)
                .disabled(email.isEmpty)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Email Sent", isPresented: $showConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Check your email for password reset instructions.")
            }
        }
    }
}

#Preview {
    SignInView(isShowingSignUp: .constant(false))
        .environmentObject(AuthViewModel())
}
