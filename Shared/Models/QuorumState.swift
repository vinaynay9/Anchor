import Foundation

public enum QuorumState: String, Codable, Hashable {
    case pending
    case satisfied
    case failed
}
