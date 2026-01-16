import Foundation
import FirebaseStorage
import UIKit

@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()

    private let storage = Storage.storage()
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false

    enum StorageError: LocalizedError {
        case invalidImage
        case uploadFailed
        case downloadFailed
        case deleteFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image data."
            case .uploadFailed:
                return "Failed to upload file."
            case .downloadFailed:
                return "Failed to download file."
            case .deleteFailed:
                return "Failed to delete file."
            }
        }
    }

    // MARK: - Avatar Upload

    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }

        let path = "avatars/\(userId).jpg"
        return try await uploadData(imageData, to: path, contentType: "image/jpeg")
    }

    // MARK: - Portfolio Upload

    func uploadPortfolioImage(image: UIImage, userId: String, itemId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        let path = "portfolios/\(userId)/\(itemId)_\(UUID().uuidString).jpg"
        return try await uploadData(imageData, to: path, contentType: "image/jpeg")
    }

    func uploadPortfolioImages(images: [UIImage], userId: String, itemId: String) async throws -> [String] {
        var urls: [String] = []

        for image in images {
            let url = try await uploadPortfolioImage(image: image, userId: userId, itemId: itemId)
            urls.append(url)
        }

        return urls
    }

    // MARK: - Post Media Upload

    func uploadPostMedia(image: UIImage, userId: String, postId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        let path = "posts/\(userId)/\(postId)_\(UUID().uuidString).jpg"
        return try await uploadData(imageData, to: path, contentType: "image/jpeg")
    }

    // MARK: - Message Attachments

    func uploadMessageAttachment(data: Data, conversationId: String, messageId: String, filename: String, contentType: String) async throws -> String {
        let path = "messages/\(conversationId)/\(messageId)_\(filename)"
        return try await uploadData(data, to: path, contentType: contentType)
    }

    // MARK: - Generic Upload

    private func uploadData(_ data: Data, to path: String, contentType: String) async throws -> String {
        isUploading = true
        uploadProgress = 0

        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putData(data, metadata: metadata)

            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let progress = snapshot.progress else { return }
                DispatchQueue.main.async {
                    self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                }
            }

            uploadTask.observe(.success) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 1.0
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }

            uploadTask.observe(.failure) { [weak self] snapshot in
                DispatchQueue.main.async {
                    self?.isUploading = false
                }
                continuation.resume(throwing: snapshot.error ?? StorageError.uploadFailed)
            }
        }
    }

    // MARK: - Delete

    func deleteFile(at path: String) async throws {
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }

    func deleteAvatar(userId: String) async throws {
        try await deleteFile(at: "avatars/\(userId).jpg")
    }

    // MARK: - Download URL

    func getDownloadURL(for path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        return try await storageRef.downloadURL()
    }
}
