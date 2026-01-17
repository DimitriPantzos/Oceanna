import Foundation
import FirebaseFirestore

@MainActor
class ConnectionService: ObservableObject {
    static let shared = ConnectionService()

    @Published var connections: [Connection] = []
    @Published var pendingRequests: [Connection] = []
    @Published var connectedUserIds: Set<String> = []
    @Published var isLoading = false

    private let db = Firestore.firestore()

    // MARK: - Connection Actions

    func sendConnectionRequest(to receiverId: String, from requesterId: String) async throws {
        let connection = Connection(
            requesterId: requesterId,
            receiverId: receiverId,
            status: .pending
        )

        let docRef = db.collection("connections").document()
        var connectionWithId = connection
        connectionWithId.id = docRef.documentID

        try docRef.setData(from: connectionWithId)
    }

    func acceptConnection(_ connection: Connection) async throws {
        guard let connectionId = connection.id else { return }

        try await db.collection("connections").document(connectionId).updateData([
            "status": ConnectionStatus.accepted.rawValue,
            "acceptedAt": Timestamp(date: Date())
        ])

        await fetchConnections(for: connection.receiverId)
    }

    func ignoreConnection(_ connection: Connection) async throws {
        guard let connectionId = connection.id else { return }

        try await db.collection("connections").document(connectionId).updateData([
            "status": ConnectionStatus.ignored.rawValue
        ])

        await fetchPendingRequests(for: connection.receiverId)
    }

    func removeConnection(_ connection: Connection) async throws {
        guard let connectionId = connection.id else { return }
        try await db.collection("connections").document(connectionId).delete()
    }

    // MARK: - Fetching

    func fetchConnections(for userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch where user is requester
            let requesterSnapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.accepted.rawValue)
                .getDocuments()

            // Fetch where user is receiver
            let receiverSnapshot = try await db.collection("connections")
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.accepted.rawValue)
                .getDocuments()

            let requesterConnections = requesterSnapshot.documents.compactMap { try? $0.data(as: Connection.self) }
            let receiverConnections = receiverSnapshot.documents.compactMap { try? $0.data(as: Connection.self) }

            connections = requesterConnections + receiverConnections

            // Build set of connected user IDs
            connectedUserIds = Set(connections.flatMap { conn in
                [conn.requesterId, conn.receiverId].filter { $0 != userId }
            })
        } catch {
            print("Error fetching connections: \(error.localizedDescription)")
        }
    }

    func fetchPendingRequests(for userId: String) async {
        do {
            let snapshot = try await db.collection("connections")
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.pending.rawValue)
                .getDocuments()

            pendingRequests = snapshot.documents.compactMap { try? $0.data(as: Connection.self) }
        } catch {
            print("Error fetching pending requests: \(error.localizedDescription)")
        }
    }

    // MARK: - Queries

    func isConnected(with userId: String) -> Bool {
        connectedUserIds.contains(userId)
    }

    func hasPendingRequest(to userId: String, from currentUserId: String) async -> Bool {
        do {
            let snapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: currentUserId)
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: ConnectionStatus.pending.rawValue)
                .getDocuments()

            return !snapshot.documents.isEmpty
        } catch {
            return false
        }
    }

    func getConnectionStatus(with userId: String, currentUserId: String) async -> ConnectionStatus? {
        do {
            // Check if current user sent request
            let sentSnapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: currentUserId)
                .whereField("receiverId", isEqualTo: userId)
                .getDocuments()

            if let doc = sentSnapshot.documents.first,
               let connection = try? doc.data(as: Connection.self) {
                return connection.status
            }

            // Check if current user received request
            let receivedSnapshot = try await db.collection("connections")
                .whereField("requesterId", isEqualTo: userId)
                .whereField("receiverId", isEqualTo: currentUserId)
                .getDocuments()

            if let doc = receivedSnapshot.documents.first,
               let connection = try? doc.data(as: Connection.self) {
                return connection.status
            }

            return nil
        } catch {
            return nil
        }
    }
}
