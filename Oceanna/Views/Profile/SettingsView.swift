import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Location Services", isOn: $locationEnabled)
                } header: {
                    Text("Preferences")
                }

                Section {
                    NavigationLink("Privacy Policy") {
                        WebViewPlaceholder(title: "Privacy Policy")
                    }
                    NavigationLink("Terms of Service") {
                        WebViewPlaceholder(title: "Terms of Service")
                    }
                    NavigationLink("Help & Support") {
                        WebViewPlaceholder(title: "Help & Support")
                    }
                } header: {
                    Text("Legal")
                }

                Section {
                    Button("Sign Out") {
                        authViewModel.signOut()
                        dismiss()
                    }
                    .foregroundColor(.blue)

                    Button("Delete Account") {
                        showDeleteAlert = true
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Account")
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("Oceanna")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }
}

struct WebViewPlaceholder: View {
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(.title)
            Text("Content would be loaded here")
                .foregroundColor(.secondary)
        }
        .navigationTitle(title)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
