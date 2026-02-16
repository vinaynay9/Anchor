import Foundation

struct AuditEvent: Codable {
    let type: AuditEventType
    let reason: String?
    let durationMinutes: Int?
    let notifiedAnchorIds: [UUID]?
}

enum AuditEventType: String, Codable {
    case emergencyUnanchor
}

protocol AuditServiceProtocol {
    func recordEvent(_ event: AuditEvent)
}

final class AuditService: AuditServiceProtocol {
    static let shared = AuditService()

    private init() {}

    func recordEvent(_ event: AuditEvent) {
        // Placeholder for future persistence/export
    }
}
