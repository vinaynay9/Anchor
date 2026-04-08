import Foundation
import Shared

@MainActor
final class GoalSetupViewModel: ObservableObject {

    // MARK: - Goal Draft

    struct GoalDraft: Identifiable, Hashable {
        let id: UUID
        var title: String
        var category: GoalCategory
        var notes: String
        var isNotesExpanded: Bool

        init(
            id: UUID = UUID(),
            title: String = "",
            category: GoalCategory = .fitness,
            notes: String = "",
            isNotesExpanded: Bool = false
        ) {
            self.id = id
            self.title = title
            self.category = category
            self.notes = notes
            self.isNotesExpanded = isNotesExpanded
        }
    }

    // MARK: - Published State

    @Published var drafts: [GoalDraft] = []

    static let minimumGoals = 3
    static let maximumGoals = 7

    var canAddMore: Bool { drafts.count < Self.maximumGoals }

    var meetsMinimum: Bool { validDraftCount >= Self.minimumGoals }

    /// Number of drafts that have a non-empty title.
    var validDraftCount: Int {
        drafts.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var canContinue: Bool { meetsMinimum }

    // MARK: - Counter label shown in the UI

    var counterText: String {
        let v = validDraftCount
        let min = Self.minimumGoals
        if v >= min {
            return "\(v)/\(min) minimum goals added ✓"
        }
        return "\(v)/\(min) minimum goals"
    }

    var counterMet: Bool { validDraftCount >= Self.minimumGoals }

    // MARK: - Init

    init() {
        // Start with 3 empty drafts so the minimum is visible immediately.
        drafts = (0..<Self.minimumGoals).map { _ in GoalDraft() }
    }

    // MARK: - Mutations

    func addGoal() {
        guard canAddMore else { return }
        let draft = GoalDraft()
        drafts.append(draft)
    }

    func remove(id: UUID) {
        drafts.removeAll { $0.id == id }
    }

    func toggleNotes(id: UUID) {
        guard let idx = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[idx].isNotesExpanded.toggle()
    }

    // MARK: - Output

    func buildGoals() -> [Shared.Goal] {
        drafts
            .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { draft in
                Shared.Goal(
                    id: draft.id,
                    title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: draft.category,
                    customCategoryName: nil
                )
            }
    }
}
