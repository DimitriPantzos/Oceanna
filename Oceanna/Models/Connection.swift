import Foundation
import FirebaseFirestore

enum ConnectionStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case ignored = "ignored"
}

struct Connection: Identifiable, Codable {
    @DocumentID var id: String?
    var requesterId: String
    var receiverId: String
    var status: ConnectionStatus
    var createdAt: Date
    var acceptedAt: Date?

    init(
        id: String? = nil,
        requesterId: String,
        receiverId: String,
        status: ConnectionStatus = .pending,
        createdAt: Date = Date(),
        acceptedAt: Date? = nil
    ) {
        self.id = id
        self.requesterId = requesterId
        self.receiverId = receiverId
        self.status = status
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
    }
}

extension Connection {
    static let example = Connection(
        id: "conn123",
        requesterId: "user1",
        receiverId: "user2",
        status: .accepted,
        acceptedAt: Date()
    )
}
