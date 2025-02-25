import Foundation

enum DatabaseError: Error, LocalizedError {
    case connectionFailed
    case queryFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to the database"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .insertFailed(let message):
            return "Insert failed: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .notFound:
            return "Item not found in the database"
        }
    }
}
