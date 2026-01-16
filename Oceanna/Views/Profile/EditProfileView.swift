import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    // Freelancer fields
    @State private var skills: [String] = []
    @State private var newSkill = ""
    @State private var hourlyRate: String = ""
    @State private var locationRadius: Double = 25
    @State private var isAvailable = true

    // Client fields
    @State private var businessName: String = ""
    @State private var industry: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Avatar Section
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let avatarUrl = viewModel.user?.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    avatarPlaceholder
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                avatarPlaceholder
                            }
                        }
                        Spacer()
                    }
                } header: {
                    Text("Profile Photo")
                }

                // Basic Info
                Section {
                    TextField("Display Name", text: $displayName)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Basic Info")
                }

                // Freelancer-specific fields
                if viewModel.user?.userType == .freelancer {
                    Section {
                        HStack {
                            Text("$")
                            TextField("Hourly Rate", text: $hourlyRate)
                                .keyboardType(.decimalPad)
                            Text("/ hour")
                                .foregroundColor(.secondary)
                        }

                        Toggle("Available for Work", isOn: $isAvailable)

                        VStack(alignment: .leading) {
                            Text("Location Radius: \(Int(locationRadius)) miles")
                            Slider(value: $locationRadius, in: 5...100, step: 5)
                        }
                    } header: {
                        Text("Work Preferences")
                    }

                    Section {
                        ForEach(skills, id: \.self) { skill in
                            HStack {
                                Text(skill)
                                Spacer()
                                Button {
                                    skills.removeAll { $0 == skill }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        HStack {
                            TextField("Add skill", text: $newSkill)
                            Button {
                                if !newSkill.isEmpty && !skills.contains(newSkill) {
                                    skills.append(newSkill)
                                    newSkill = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newSkill.isEmpty)
                        }
                    } header: {
                        Text("Skills")
                    }
                }

                // Client-specific fields
                if viewModel.user?.userType == .client {
                    Section {
                        TextField("Business Name", text: $businessName)
                        TextField("Industry", text: $industry)
                    } header: {
                        Text("Business Info")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            )
    }

    private func loadCurrentValues() {
        if let user = viewModel.user {
            displayName = user.displayName
            bio = user.bio ?? ""
        }

        if let profile = viewModel.freelancerProfile {
            skills = profile.skills
            hourlyRate = profile.hourlyRate.map { String(format: "%.0f", $0) } ?? ""
            locationRadius = profile.locationRadius
            isAvailable = profile.availability.isAvailable
        }

        if let profile = viewModel.clientProfile {
            businessName = profile.businessName ?? ""
            industry = profile.industry ?? ""
        }
    }

    private func saveProfile() {
        Task {
            // Update avatar if changed
            if let image = selectedImage {
                await viewModel.updateAvatar(image: image)
            }

            // Update user
            if var user = viewModel.user {
                user.displayName = displayName
                user.bio = bio.isEmpty ? nil : bio
                await viewModel.updateUser(user)
            }

            // Update type-specific profile
            if var profile = viewModel.freelancerProfile {
                profile.skills = skills
                profile.hourlyRate = Double(hourlyRate)
                profile.locationRadius = locationRadius
                profile.availability.isAvailable = isAvailable
                await viewModel.updateFreelancerProfile(profile)
            }

            if var profile = viewModel.clientProfile {
                profile.businessName = businessName.isEmpty ? nil : businessName
                profile.industry = industry.isEmpty ? nil : industry
                await viewModel.updateClientProfile(profile)
            }

            dismiss()
        }
    }
}

#Preview {
    EditProfileView(viewModel: ProfileViewModel())
}
