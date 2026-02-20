import Foundation

public struct Goal: Codable, Hashable, Identifiable {
    public let id: UUID
    public var title: String
    public var category: GoalCategory
    public var customCategoryName: String?

    public init(id: UUID = UUID(), title: String, category: GoalCategory, customCategoryName: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.customCategoryName = customCategoryName
    }
}
