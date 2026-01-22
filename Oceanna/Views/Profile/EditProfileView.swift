import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var city = ""
    @State private var bio = ""
    @State private var skills: [String] = []
    @State private var lookingFor: [String] = []
    @State private var availability: Availability = .both
    @State private var newSkill = ""
    @State private var newLookingFor = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: OceannaTheme.Spacing.lg) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.md) {
                        Text("Basic Info")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(OceannaTextFieldStyle())

                        TextField("City, State", text: $city)
                            .textFieldStyle(OceannaTextFieldStyle())

                        TextField("Bio", text: $bio, axis: .vertical)
                            .textFieldStyle(OceannaTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)

                    // Skills
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.md) {
                        Text("Skills")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        HStack {
                            TextField("Add skill", text: $newSkill)
                                .textFieldStyle(OceannaTextFieldStyle())

                            Button {
                                if !newSkill.isEmpty {
                                    skills.append(newSkill)
                                    newSkill = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(OceannaTheme.Colors.primary)
                            }
                        }

                        FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                            ForEach(skills, id: \.self) { skill in
                                HStack(spacing: OceannaTheme.Spacing.xxs) {
                                    Text(skill)
                                    Button {
                                        skills.removeAll { $0 == skill }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10))
                                    }
                                }
                                .monoTag()
                            }
                        }
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)

                    // Looking For
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.md) {
                        Text("Looking For")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        HStack {
                            TextField("Add what you're looking for", text: $newLookingFor)
                                .textFieldStyle(OceannaTextFieldStyle())

                            Button {
                                if !newLookingFor.isEmpty {
                                    lookingFor.append(newLookingFor)
                                    newLookingFor = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(OceannaTheme.Colors.primary)
                            }
                        }

                        FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                            ForEach(lookingFor, id: \.self) { item in
                                HStack(spacing: OceannaTheme.Spacing.xxs) {
                                    Text(item)
                                    Button {
                                        lookingFor.removeAll { $0 == item }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10))
                                    }
                                }
                                .monoTag()
                            }
                        }
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)

                    // Availability
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.md) {
                        Text("Availability")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        ForEach(Availability.allCases, id: \.self) { option in
                            Button {
                                availability = option
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                        .font(OceannaTheme.Typography.body)
                                        .foregroundColor(OceannaTheme.Colors.primaryText)
                                    Spacer()
                                    if availability == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(OceannaTheme.Colors.primary)
                                    }
                                }
                                .padding(OceannaTheme.Spacing.md)
                                .background(OceannaTheme.Colors.secondaryBackground)
                                .cornerRadius(OceannaTheme.Radius.sm)
                            }
                        }
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)

                    if let error = errorMessage {
                        Text(error)
                            .font(OceannaTheme.Typography.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, OceannaTheme.Spacing.lg)
            }
            .background(OceannaTheme.Colors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(OceannaTheme.Colors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(OceannaTheme.Colors.primary)
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }

    private func loadCurrentProfile() {
        guard let user = authViewModel.userProfile else { return }
        displayName = user.displayName
        city = user.city
        bio = user.bio ?? ""
        skills = user.skills
        lookingFor = user.lookingFor
        availability = user.availability
    }

    private func save() {
        guard var user = authViewModel.userProfile else { return }

        isLoading = true
        errorMessage = nil

        user.displayName = displayName
        user.city = city
        user.bio = bio.isEmpty ? nil : bio
        user.skills = skills
        user.lookingFor = lookingFor
        user.availability = availability

        Task {
            await authViewModel.updateUserProfile(user)
            errorMessage = authViewModel.errorMessage
            if errorMessage == nil {
                dismiss()
            }
            isLoading = false
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}
