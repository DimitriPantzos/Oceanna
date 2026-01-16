import Foundation
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var freelancerProfile: FreelancerProfile?
    @Published var clientProfile: ClientProfile?
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private let storageService = StorageService.shared
    private let authService = AuthService.shared

    // MARK: - Load Profile

    func loadProfile(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await firestoreService.getUser(id: userId)

            if let user = user {
                if user.userType == .freelancer {
                    freelancerProfile = try await firestoreService.getFreelancerProfile(userId: userId)
                } else {
                    clientProfile = try await firestoreService.getClientProfile(userId: userId)
                }
            }

            reviews = try await firestoreService.getReviews(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCurrentUserProfile() async {
        guard let userId = authService.currentUser?.uid else { return }
        await loadProfile(userId: userId)
    }

    // MARK: - Update User

    func updateUser(_ updatedUser: User) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await authService.updateUserProfile(updatedUser)
            user = updatedUser
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateAvatar(image: UIImage) async {
        guard let userId = user?.id else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            let avatarUrl = try await storageService.uploadAvatar(image: image, userId: userId)

            if var updatedUser = user {
                updatedUser.avatarUrl = avatarUrl
                try await authService.updateUserProfile(updatedUser)
                user = updatedUser
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Freelancer Profile

    func updateFreelancerProfile(_ profile: FreelancerProfile) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await firestoreService.updateFreelancerProfile(profile)
            freelancerProfile = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSkill(_ skill: String) async {
        guard var profile = freelancerProfile else { return }
        if !profile.skills.contains(skill) {
            profile.skills.append(skill)
            await updateFreelancerProfile(profile)
        }
    }

    func removeSkill(_ skill: String) async {
        guard var profile = freelancerProfile else { return }
        profile.skills.removeAll { $0 == skill }
        await updateFreelancerProfile(profile)
    }

    func addService(_ service: Service) async {
        guard var profile = freelancerProfile else { return }
        profile.services.append(service)
        await updateFreelancerProfile(profile)
    }

    func removeService(_ serviceId: String) async {
        guard var profile = freelancerProfile else { return }
        profile.services.removeAll { $0.id == serviceId }
        await updateFreelancerProfile(profile)
    }

    func addPortfolioItem(_ item: PortfolioItem) async {
        guard var profile = freelancerProfile else { return }
        profile.portfolio.append(item)
        await updateFreelancerProfile(profile)
    }

    func addPortfolioItemWithImages(title: String, description: String?, images: [UIImage], tags: [String]) async {
        guard let userId = user?.id, var profile = freelancerProfile else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            let itemId = UUID().uuidString
            let imageUrls = try await storageService.uploadPortfolioImages(images: images, userId: userId, itemId: itemId)

            let item = PortfolioItem(
                id: itemId,
                title: title,
                description: description,
                imageUrls: imageUrls,
                createdAt: Date(),
                tags: tags
            )

            profile.portfolio.append(item)
            try await firestoreService.updateFreelancerProfile(profile)
            freelancerProfile = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Client Profile

    func updateClientProfile(_ profile: ClientProfile) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await firestoreService.updateClientProfile(profile)
            clientProfile = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reviews

    func submitReview(for revieweeId: String, projectId: String, rating: Double, title: String?, content: String, categories: [Review.CategoryRating]) async {
        guard let reviewerId = user?.id, let userType = user?.userType else { return }

        let review = Review(
            projectId: projectId,
            reviewerId: reviewerId,
            revieweeId: revieweeId,
            reviewerType: userType,
            rating: rating,
            title: title,
            content: content,
            categories: categories
        )

        do {
            try await firestoreService.createReview(review)
            reviews.insert(review, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
