import Foundation
import FirebaseFirestore

@MainActor
class MatchingService: ObservableObject {
    static let shared = MatchingService()

    private let db = Firestore.firestore()
    private let firestoreService = FirestoreService.shared

    // MARK: - Freelancer Matching for Projects

    struct MatchScore: Identifiable {
        var id: String { freelancerId }
        var freelancerId: String
        var score: Double
        var matchReasons: [String]
    }

    func findMatchingFreelancers(for project: Project, limit: Int = 10) async throws -> [MatchScore] {
        // Fetch all freelancers (in production, use more efficient querying)
        let freelancers = try await firestoreService.searchFreelancers()

        var scores: [MatchScore] = []

        for freelancer in freelancers {
            guard let freelancerId = freelancer.id else { continue }

            var score: Double = 0
            var reasons: [String] = []

            // Skill matching
            let matchingSkills = Set(freelancer.skills).intersection(Set(project.skills))
            if !matchingSkills.isEmpty {
                score += Double(matchingSkills.count) * 15
                reasons.append("\(matchingSkills.count) matching skill(s)")
            }

            // Category matching
            if freelancer.categories.contains(project.category) {
                score += 20
                reasons.append("Category match: \(project.category)")
            }

            // Availability
            if freelancer.availability.isAvailable {
                score += 10
                reasons.append("Currently available")
            }

            // Rating bonus
            if freelancer.rating >= 4.5 {
                score += 15
                reasons.append("Highly rated (\(String(format: "%.1f", freelancer.rating)))")
            } else if freelancer.rating >= 4.0 {
                score += 10
                reasons.append("Well rated (\(String(format: "%.1f", freelancer.rating)))")
            }

            // Experience bonus
            if let years = freelancer.yearsOfExperience, years >= 3 {
                score += 10
                reasons.append("\(years)+ years experience")
            }

            // Response time bonus
            if freelancer.responseTime != nil {
                score += 5
                reasons.append("Fast responder")
            }

            // Open to collaboration
            if freelancer.isOpenToCollaboration {
                score += 5
                reasons.append("Open to collaboration")
            }

            // Completed projects bonus
            if freelancer.completedProjects >= 10 {
                score += 10
                reasons.append("\(freelancer.completedProjects) completed projects")
            }

            if score > 0 {
                scores.append(MatchScore(freelancerId: freelancerId, score: score, matchReasons: reasons))
            }
        }

        // Sort by score and return top matches
        return scores.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    // MARK: - Collaborator Matching

    struct CollaboratorMatch: Identifiable {
        var id: String { freelancerId }
        var freelancerId: String
        var complementarySkills: [String]
        var sharedInterests: [String]
        var compatibilityScore: Double
    }

    func findCollaborators(for freelancer: FreelancerProfile, limit: Int = 10) async throws -> [CollaboratorMatch] {
        let allFreelancers = try await firestoreService.searchFreelancers()

        var matches: [CollaboratorMatch] = []

        for other in allFreelancers {
            guard let otherId = other.id, otherId != freelancer.id else { continue }

            // Find complementary skills (skills the other has that we don't)
            let mySkills = Set(freelancer.skills)
            let theirSkills = Set(other.skills)
            let complementary = theirSkills.subtracting(mySkills)

            // Find shared categories/interests
            let myCategories = Set(freelancer.categories)
            let theirCategories = Set(other.categories)
            let shared = myCategories.intersection(theirCategories)

            // Calculate compatibility score
            var score: Double = 0

            // Complementary skills are valuable
            score += Double(complementary.count) * 10

            // Some shared interests for collaboration context
            score += Double(shared.count) * 5

            // Both open to collaboration
            if other.isOpenToCollaboration && freelancer.isOpenToCollaboration {
                score += 15
            }

            // Good ratings
            if other.rating >= 4.0 {
                score += 10
            }

            // Available
            if other.availability.isAvailable {
                score += 10
            }

            if score > 20 && !complementary.isEmpty {
                matches.append(CollaboratorMatch(
                    freelancerId: otherId,
                    complementarySkills: Array(complementary),
                    sharedInterests: Array(shared),
                    compatibilityScore: score
                ))
            }
        }

        return matches.sorted { $0.compatibilityScore > $1.compatibilityScore }.prefix(limit).map { $0 }
    }

    // MARK: - Project Recommendations for Freelancers

    struct ProjectRecommendation: Identifiable {
        var id: String { projectId }
        var projectId: String
        var matchScore: Double
        var matchReasons: [String]
    }

    func recommendProjects(for freelancer: FreelancerProfile, limit: Int = 10) async throws -> [ProjectRecommendation] {
        let openProjects = try await firestoreService.getOpenProjects(limit: 50)

        var recommendations: [ProjectRecommendation] = []

        for project in openProjects {
            guard let projectId = project.id else { continue }

            var score: Double = 0
            var reasons: [String] = []

            // Skill match
            let matchingSkills = Set(freelancer.skills).intersection(Set(project.skills))
            if !matchingSkills.isEmpty {
                score += Double(matchingSkills.count) * 20
                reasons.append("Skills match: \(matchingSkills.joined(separator: ", "))")
            }

            // Category match
            if freelancer.categories.contains(project.category) {
                score += 25
                reasons.append("Your specialty: \(project.category)")
            }

            // Budget alignment with hourly rate
            if let hourlyRate = freelancer.hourlyRate,
               let minBudget = project.budget.min {
                // Rough estimate if project could be profitable
                let estimatedHours = minBudget / hourlyRate
                if estimatedHours >= 5 {
                    score += 15
                    reasons.append("Good budget fit")
                }
            }

            // Urgent projects might be more valuable
            if project.isUrgent && freelancer.availability.isAvailable {
                score += 10
                reasons.append("Urgent - you're available!")
            }

            // Work style preference
            if project.workStyle == .flexible {
                score += 5
                reasons.append("Flexible work style")
            }

            if score > 20 {
                recommendations.append(ProjectRecommendation(
                    projectId: projectId,
                    matchScore: score,
                    matchReasons: reasons
                ))
            }
        }

        return recommendations.sorted { $0.matchScore > $1.matchScore }.prefix(limit).map { $0 }
    }

    // MARK: - Swipe Mode Matching

    func getSwipeProfiles(for user: User, location: GeoPoint?, radiusMiles: Double = 50, limit: Int = 20) async throws -> [FreelancerProfile] {
        // Get nearby freelancers for swipe-to-connect feature
        if let location = location {
            return try await firestoreService.getNearbyFreelancers(center: location, radiusMiles: radiusMiles, limit: limit)
        } else {
            return try await firestoreService.searchFreelancers()
        }
    }
}
