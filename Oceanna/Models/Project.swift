import Foundation
import FirebaseFirestore

struct Project: Identifiable, Codable {
    @DocumentID var id: String?
    var clientId: String
    var title: String
    var description: String
    var category: String
    var skills: [String]
    var budget: Budget
    var timeline: Timeline
    var location: GeoPoint?
    var locationRadius: Double?
    var workStyle: ProjectPreferences.WorkStyle
    var status: ProjectStatus
    var createdAt: Date
    var updatedAt: Date
    var applicants: [String] // Freelancer IDs who applied
    var hiredFreelancerId: String?
    var attachments: [String] // URLs to attached files
    var isUrgent: Bool
    var viewCount: Int

    struct Budget: Codable {
        var min: Double?
        var max: Double?
        var type: BudgetType

        enum BudgetType: String, Codable, CaseIterable {
            case fixed = "Fixed"
            case hourly = "Hourly"
            case negotiable = "Negotiable"
        }

        var displayString: String {
            switch type {
            case .fixed, .hourly:
                if let min = min, let max = max {
                    return "$\(Int(min)) - $\(Int(max))\(type == .hourly ? "/hr" : "")"
                } else if let min = min {
                    return "From $\(Int(min))\(type == .hourly ? "/hr" : "")"
                } else if let max = max {
                    return "Up to $\(Int(max))\(type == .hourly ? "/hr" : "")"
                }
                return type.rawValue
            case .negotiable:
                return "Negotiable"
            }
        }
    }

    struct Timeline: Codable {
        var startDate: Date?
        var endDate: Date?
        var duration: String?
        var isFlexible: Bool

        var displayString: String {
            if let duration = duration {
                return duration
            }
            if let start = startDate, let end = endDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
            }
            return isFlexible ? "Flexible" : "To be discussed"
        }
    }

    enum ProjectStatus: String, Codable, CaseIterable {
        case draft = "Draft"
        case open = "Open"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
        case onHold = "On Hold"
    }

    init(
        id: String? = nil,
        clientId: String,
        title: String,
        description: String,
        category: String,
        skills: [String] = [],
        budget: Budget,
        timeline: Timeline,
        location: GeoPoint? = nil,
        locationRadius: Double? = nil,
        workStyle: ProjectPreferences.WorkStyle = .flexible,
        status: ProjectStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        applicants: [String] = [],
        hiredFreelancerId: String? = nil,
        attachments: [String] = [],
        isUrgent: Bool = false,
        viewCount: Int = 0
    ) {
        self.id = id
        self.clientId = clientId
        self.title = title
        self.description = description
        self.category = category
        self.skills = skills
        self.budget = budget
        self.timeline = timeline
        self.location = location
        self.locationRadius = locationRadius
        self.workStyle = workStyle
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.applicants = applicants
        self.hiredFreelancerId = hiredFreelancerId
        self.attachments = attachments
        self.isUrgent = isUrgent
        self.viewCount = viewCount
    }
}

extension Project {
    static let example = Project(
        id: "project123",
        clientId: "client123",
        title: "Mural Design for Coffee Shop",
        description: "Looking for a talented mural artist to create a vibrant, coffee-themed mural for our new location. The wall is approximately 15x8 feet.",
        category: "Art & Illustration",
        skills: ["Mural Art", "Illustration", "Painting"],
        budget: Budget(min: 2000, max: 3500, type: .fixed),
        timeline: Timeline(startDate: nil, endDate: nil, duration: "2-3 weeks", isFlexible: true),
        workStyle: .inPerson,
        status: .open,
        isUrgent: false,
        viewCount: 45
    )
}
