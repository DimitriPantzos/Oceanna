import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FeedViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var content = ""
    @State private var postType: FeedPost.PostType = .update
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var visibility: FeedPost.Visibility = .publicPost

    // Collaboration fields
    @State private var isCollaboration = false
    @State private var collabTitle = ""
    @State private var collabDescription = ""
    @State private var rolesNeeded: [String] = []
    @State private var newRole = ""
    @State private var isPaid = false
    @State private var deadline: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var hasDeadline = false

    var isValid: Bool {
        !content.isEmpty && (postType != .collaborationRequest || (!collabTitle.isEmpty && !rolesNeeded.isEmpty))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Post Type
                Section {
                    Picker("Post Type", selection: $postType) {
                        ForEach(FeedPost.PostType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: postType) { _, newValue in
                        isCollaboration = newValue == .collaborationRequest
                    }
                }

                // Content
                Section {
                    TextField("What's on your mind?", text: $content, axis: .vertical)
                        .lineLimit(5...10)
                } header: {
                    Text("Content")
                }

                // Collaboration Details
                if isCollaboration {
                    Section {
                        TextField("Collaboration Title", text: $collabTitle)

                        TextField("Description", text: $collabDescription, axis: .vertical)
                            .lineLimit(3...5)

                        Toggle("Paid Opportunity", isOn: $isPaid)

                        Toggle("Has Deadline", isOn: $hasDeadline)

                        if hasDeadline {
                            DatePicker("Apply By", selection: $deadline, displayedComponents: .date)
                        }
                    } header: {
                        Text("Collaboration Details")
                    }

                    Section {
                        ForEach(rolesNeeded, id: \.self) { role in
                            HStack {
                                Text(role)
                                Spacer()
                                Button {
                                    rolesNeeded.removeAll { $0 == role }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        HStack {
                            TextField("Add role needed", text: $newRole)
                            Button {
                                if !newRole.isEmpty {
                                    rolesNeeded.append(newRole)
                                    newRole = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newRole.isEmpty)
                        }
                    } header: {
                        Text("Roles Needed")
                    }
                }

                // Photos
                Section {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Add Photos")
                        }
                    }

                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                selectedImages.remove(at: index)
                                                selectedPhotos.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                            }
                                            .padding(4)
                                        }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Media")
                }

                // Tags
                Section {
                    FlowLayout(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                    }

                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textInputAutocapitalization(.never)
                        Button {
                            if !newTag.isEmpty {
                                tags.append(newTag.lowercased())
                                newTag = ""
                            }
                        } label: {
                            Text("Add")
                        }
                        .disabled(newTag.isEmpty)
                    }
                } header: {
                    Text("Tags")
                }

                // Visibility
                Section {
                    Picker("Who can see this?", selection: $visibility) {
                        ForEach(FeedPost.Visibility.allCases, id: \.self) { vis in
                            Text(vis.rawValue).tag(vis)
                        }
                    }
                } header: {
                    Text("Visibility")
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        createPost()
                    }
                    .disabled(!isValid || viewModel.isPosting)
                }
            }
            .onChange(of: selectedPhotos) { _, newItems in
                Task {
                    selectedImages = []
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }

    private func createPost() {
        guard let userId = authViewModel.currentUser?.id else { return }

        Task {
            if isCollaboration {
                await viewModel.createCollaborationRequest(
                    authorId: userId,
                    title: collabTitle,
                    description: collabDescription,
                    rolesNeeded: rolesNeeded,
                    isPaid: isPaid,
                    deadline: hasDeadline ? deadline : nil,
                    tags: tags
                )
            } else {
                await viewModel.createPost(
                    authorId: userId,
                    content: content,
                    postType: postType,
                    images: selectedImages,
                    tags: tags,
                    visibility: visibility
                )
            }
            dismiss()
        }
    }
}

#Preview {
    CreatePostView(viewModel: FeedViewModel())
        .environmentObject(AuthViewModel())
}
