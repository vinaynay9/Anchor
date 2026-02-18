import Foundation

public struct V0Goal: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var categories: [V0GoalCategory]
    public let createdAt: Date

    public init(id: UUID = UUID(), title: String, categories: [V0GoalCategory], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.categories = categories
        self.createdAt = createdAt
    }
}
