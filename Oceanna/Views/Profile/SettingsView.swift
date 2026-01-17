import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Privacy Section
                Section {
                    if let user = authService.userProfile {
                        NavigationLink {
                            PrivacySettingsView(visibility: user.visibility)
                        } label: {
                            Label("Privacy", systemImage: "lock")
                        }
                    }
                } header: {
                    Text("Privacy")
                }

                // Account Section
                Section {
                    Button {
                        showingSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(OceannaTheme.Colors.primaryText)
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                } header: {
                    Text("Account")
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(OceannaTheme.Colors.secondaryText)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(OceannaTheme.Colors.primary)
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        try? await authService.deleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State var visibility: ProfileVisibility

    var body: some View {
        List {
            Section {
                Toggle("Show Skills", isOn: $visibility.showSkills)
                Toggle("Show Portfolio", isOn: $visibility.showPortfolio)
                Toggle("Show Bio", isOn: $visibility.showBio)
                Toggle("Show City", isOn: $visibility.showCity)
            } header: {
                Text("Visible to non-connections")
            } footer: {
                Text("Connections can always see your full profile.")
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: visibility) { _, newValue in
            saveVisibility(newValue)
        }
        .tint(OceannaTheme.Colors.primary)
    }

    private func saveVisibility(_ visibility: ProfileVisibility) {
        guard var user = authService.userProfile else { return }
        user.visibility = visibility
        Task {
            try? await authService.updateUserProfile(user)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService.shared)
}
