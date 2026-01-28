import Foundation
import Shared

// MARK: - Service Rewrite Decision
// LockPlanService is NEW. It becomes the source of truth for plan intent and replaces session-first flows.

enum LockPlanServiceError: Error {
    case planNotEditable
    case planNotDeletable
    case planNotFound
}

protocol LockPlanServiceProtocol {
    func loadPlans() -> [LockPlan]
    func savePlans(_ plans: [LockPlan])
    func createPlan(_ plan: LockPlan) -> LockPlan
    func updatePlan(_ plan: LockPlan) throws -> LockPlan
    func deletePlan(id: UUID) throws
    func seedDefaultPlansIfNeeded() -> [LockPlan]
}

final class LockPlanService: LockPlanServiceProtocol {
    static let shared = LockPlanService()
    
    private let appGroupStorage = AppGroupStorage.shared
    
    private init() {}
    
    func loadPlans() -> [LockPlan] {
        appGroupStorage.getLockPlans()
    }
    
    func savePlans(_ plans: [LockPlan]) {
        appGroupStorage.setLockPlans(plans)
    }
    
    func createPlan(_ plan: LockPlan) -> LockPlan {
        var plans = loadPlans()
        plans.append(plan)
        savePlans(plans)
        return plan
    }
    
    func updatePlan(_ plan: LockPlan) throws -> LockPlan {
        var plans = loadPlans()
        guard let index = plans.firstIndex(where: { $0.id == plan.id }) else {
            throw LockPlanServiceError.planNotFound
        }
        let existing = plans[index]
        guard existing.isEditable else {
            throw LockPlanServiceError.planNotEditable
        }
        plans[index] = plan
        savePlans(plans)
        return plan
    }
    
    func deletePlan(id: UUID) throws {
        var plans = loadPlans()
        guard let existing = plans.first(where: { $0.id == id }) else {
            throw LockPlanServiceError.planNotFound
        }
        guard existing.isEditable, existing.consequencePolicy?.lockPlanDeletionDisabled != true else {
            throw LockPlanServiceError.planNotDeletable
        }
        plans.removeAll { $0.id == id }
        savePlans(plans)
    }
    
    func seedDefaultPlansIfNeeded() -> [LockPlan] {
        let existing = loadPlans()
        guard existing.isEmpty else { return existing }
        let defaults = LockPlan.recommendedDefaults()
        savePlans(defaults)
        return defaults
    }
}

