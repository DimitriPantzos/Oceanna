import Foundation
import FirebaseFirestore

struct ProjectPreferences: Codable {
    var preferredCategories: [String]
    var typicalBudgetRange: BudgetRange
    var typicalTimeline: TimelinePreference
    var preferredWorkStyle: WorkStyle

    enum BudgetRange: String, Codable, CaseIterable {
        case under500 = "Under $500"
        case range500to2000 = "$500 - $2,000"
        case range2000to5000 = "$2,000 - $5,000"
        case range5000to10000 = "$5,000 - $10,000"
        case over10000 = "$10,000+"
        case negotiable = "Negotiable"
    }

    enum TimelinePreference: String, Codable, CaseIterable {
        case urgent = "Urgent (< 1 week)"
        case short = "Short (1-2 weeks)"
        case medium = "Medium (2-4 weeks)"
        case long = "Long (1-3 months)"
        case flexible = "Flexible"
    }

    enum WorkStyle: String, Codable, CaseIterable {
        case remote = "Remote"
        case inPerson = "In-Person"
        case hybrid = "Hybrid"
        case flexible = "Flexible"
    }
}

struct ClientProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var businessName: String?
    var businessType: BusinessType
    var industry: String?
    var website: String?
    var projectPreferences: ProjectPreferences
    var hireHistory: [String] // Project IDs
    var rating: Double
    var reviewCount: Int
    var totalProjectsPosted: Int
    var totalHires: Int
    var isPaymentVerified: Bool
    var companySize: CompanySize?
    var description: String?

    enum BusinessType: String, Codable, CaseIterable {
        case individual = "Individual"
        case startup = "Startup"
        case smallBusiness = "Small Business"
        case mediumBusiness = "Medium Business"
        case enterprise = "Enterprise"
        case nonprofit = "Nonprofit"
        case agency = "Agency"
    }

    enum CompanySize: String, Codable, CaseIterable {
        case solo = "Just me"
        case small = "2-10 employees"
        case medium = "11-50 employees"
        case large = "51-200 employees"
        case enterprise = "200+ employees"
    }

    init(
        id: String? = nil,
        userId: String,
        businessName: String? = nil,
        businessType: BusinessType = .individual,
        industry: String? = nil,
        website: String? = nil,
        projectPreferences: ProjectPreferences = ProjectPreferences(
            preferredCategories: [],
            typicalBudgetRange: .negotiable,
            typicalTimeline: .flexible,
            preferredWorkStyle: .flexible
        ),
        hireHistory: [String] = [],
        rating: Double = 0,
        reviewCount: Int = 0,
        totalProjectsPosted: Int = 0,
        totalHires: Int = 0,
        isPaymentVerified: Bool = false,
        companySize: CompanySize? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.businessName = businessName
        self.businessType = businessType
        self.industry = industry
        self.website = website
        self.projectPreferences = projectPreferences
        self.hireHistory = hireHistory
        self.rating = rating
        self.reviewCount = reviewCount
        self.totalProjectsPosted = totalProjectsPosted
        self.totalHires = totalHires
        self.isPaymentVerified = isPaymentVerified
        self.companySize = companySize
        self.description = description
    }
}

extension ClientProfile {
    static let example = ClientProfile(
        id: "client123",
        userId: "user456",
        businessName: "Creative Coffee Co.",
        businessType: .smallBusiness,
        industry: "Food & Beverage",
        website: "https://creativecoffee.com",
        projectPreferences: ProjectPreferences(
            preferredCategories: ["Design", "Marketing"],
            typicalBudgetRange: .range2000to5000,
            typicalTimeline: .medium,
            preferredWorkStyle: .hybrid
        ),
        rating: 4.9,
        reviewCount: 12,
        totalProjectsPosted: 15,
        totalHires: 12,
        isPaymentVerified: true,
        companySize: .small,
        description: "A local coffee shop looking for creative talent to help with branding and marketing"
    )
}
