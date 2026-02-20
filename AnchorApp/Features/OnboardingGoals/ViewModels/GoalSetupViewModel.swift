import Foundation
import Shared

@MainActor
final class GoalSetupViewModel: ObservableObject {
    struct GoalDraft: Identifiable, Hashable {
        let id: UUID
        var title: String
        var category: GoalCategory
        var customCategoryName: String

        init(id: UUID = UUID(), title: String = "", category: GoalCategory = .fitness, customCategoryName: String = "") {
            self.id = id
            self.title = title
            self.category = category
            self.customCategoryName = customCategoryName
        }
    }

    @Published var drafts: [GoalDraft] = Array(repeating: GoalDraft(), count: 4)
    @Published var showMaxHelper = false

    let maxGoals = 7

    var canAddMore: Bool {
        drafts.count < maxGoals
    }

    var isValid: Bool {
        drafts.allSatisfy { draft in
            let titleValid = !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let categoryValid = draft.category != .other || !draft.customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return titleValid && categoryValid
        }
    }

    func addGoal() {
        guard canAddMore else {
            showMaxHelper = true
            return
        }
        drafts.append(GoalDraft())
    }

    func buildGoals() -> [Shared.Goal] {
        drafts.map { draft in
            Shared.Goal(
                id: draft.id,
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                category: draft.category,
                customCategoryName: draft.category == .other ? draft.customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines) : nil
            )
        }
    }
}
