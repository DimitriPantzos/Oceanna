import Foundation
import FirebaseFirestore

enum PriceType: String, Codable {
    case fixed = "Fixed"
    case hourly = "Hourly"
    case daily = "Daily"
    case project = "Project"
}

struct Service: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var price: Double
    var priceType: PriceType
    var userId: String?
    var createdAt: Date

    init(
        id: String? = nil,
        name: String,
        description: String,
        price: Double,
        priceType: PriceType,
        userId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.priceType = priceType
        self.userId = userId
        self.createdAt = createdAt
    }
}

extension Service {
    static let example = Service(
        id: "service1",
        name: "Logo Design",
        description: "Custom logo design with revisions",
        price: 150,
        priceType: .fixed
    )
}
