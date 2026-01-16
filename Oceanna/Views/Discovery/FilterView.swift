import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DiscoveryViewModel

    @State private var selectedCategory: String?
    @State private var selectedSkills: Set<String> = []
    @State private var searchRadius: Double = 25
    @State private var minRating: Double = 0
    @State private var availableOnly = false

    var body: some View {
        NavigationStack {
            Form {
                // Search Radius
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Search Radius")
                            Spacer()
                            Text("\(Int(searchRadius)) miles")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $searchRadius, in: 5...100, step: 5)
                    }
                } header: {
                    Text("Location")
                }

                // Category
                Section {
                    ForEach(DiscoveryViewModel.categories, id: \.self) { category in
                        Button {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        } label: {
                            HStack {
                                Text(category)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Category")
                }

                // Skills
                Section {
                    FlowLayout(spacing: 8) {
                        ForEach(DiscoveryViewModel.popularSkills, id: \.self) { skill in
                            SkillFilterChip(
                                skill: skill,
                                isSelected: selectedSkills.contains(skill)
                            ) {
                                if selectedSkills.contains(skill) {
                                    selectedSkills.remove(skill)
                                } else {
                                    selectedSkills.insert(skill)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Skills")
                }

                // Rating
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Minimum Rating")
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text(minRating == 0 ? "Any" : String(format: "%.1f+", minRating))
                            }
                            .foregroundColor(.secondary)
                        }
                        Slider(value: $minRating, in: 0...5, step: 0.5)
                    }
                } header: {
                    Text("Quality")
                }

                // Availability
                Section {
                    Toggle("Available Now Only", isOn: $availableOnly)
                } header: {
                    Text("Availability")
                }

                // Clear Filters
                Section {
                    Button("Clear All Filters") {
                        clearFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentFilters()
            }
        }
    }

    private func loadCurrentFilters() {
        selectedCategory = viewModel.selectedCategory
        selectedSkills = Set(viewModel.selectedSkills)
        searchRadius = viewModel.searchRadius
        minRating = viewModel.minRating ?? 0
        availableOnly = viewModel.availableOnly
    }

    private func applyFilters() {
        viewModel.selectedCategory = selectedCategory
        viewModel.selectedSkills = Array(selectedSkills)
        viewModel.searchRadius = searchRadius
        viewModel.minRating = minRating > 0 ? minRating : nil
        viewModel.availableOnly = availableOnly

        Task {
            await viewModel.applyFilters()
        }
    }

    private func clearFilters() {
        selectedCategory = nil
        selectedSkills = []
        searchRadius = 25
        minRating = 0
        availableOnly = false
    }
}

struct SkillFilterChip: View {
    let skill: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(skill)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

#Preview {
    FilterView(viewModel: DiscoveryViewModel())
}
