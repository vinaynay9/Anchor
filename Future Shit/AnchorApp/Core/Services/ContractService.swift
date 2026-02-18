import Foundation
import Shared

// MARK: - Service Rewrite Decision
// ContractService is NEW. It replaces pledge/analytics-style "challenges" with enforceable social contracts.

protocol ContractServiceProtocol {
    func loadContracts() -> [SocialContract]
    func createContract(_ contract: SocialContract) -> SocialContract
    func updateContract(_ contract: SocialContract) -> SocialContract
    func resolveContract(id: UUID) -> SocialContract?
    func recordIOU(_ entry: IOULedgerEntry) -> IOULedgerEntry
    func applyConsequences(for contract: SocialContract) async
}

final class ContractService: ContractServiceProtocol {
    static let shared = ContractService()
    
    private let appGroupStorage = AppGroupStorage.shared
    private let lockPlanService: LockPlanServiceProtocol
    private let sessionService: SessionServiceProtocol
    
    init(
        lockPlanService: LockPlanServiceProtocol = LockPlanService.shared,
        sessionService: SessionServiceProtocol = SessionService.shared
    ) {
        self.lockPlanService = lockPlanService
        self.sessionService = sessionService
    }
    
    func loadContracts() -> [SocialContract] {
        appGroupStorage.getSocialContracts()
    }
    
    func createContract(_ contract: SocialContract) -> SocialContract {
        var contracts = loadContracts()
        contracts.append(contract)
        appGroupStorage.setSocialContracts(contracts)
        return contract
    }
    
    func updateContract(_ contract: SocialContract) -> SocialContract {
        var contracts = loadContracts()
        if let index = contracts.firstIndex(where: { $0.id == contract.id }) {
            contracts[index] = contract
        } else {
            contracts.append(contract)
        }
        appGroupStorage.setSocialContracts(contracts)
        return contract
    }
    
    func resolveContract(id: UUID) -> SocialContract? {
        var contracts = loadContracts()
        guard let index = contracts.firstIndex(where: { $0.id == id }) else { return nil }
        contracts[index].status = .resolved
        appGroupStorage.setSocialContracts(contracts)
        return contracts[index]
    }
    
    func recordIOU(_ entry: IOULedgerEntry) -> IOULedgerEntry {
        var ledger = appGroupStorage.getIOULedger()
        ledger.append(entry)
        appGroupStorage.setIOULedger(ledger)
        return entry
    }
    
    /// Enforcement point: apply contract consequences by mutating lock plans or extending sessions.
    func applyConsequences(for contract: SocialContract) async {
        let consequences = contract.consequences
        
        if consequences.lockPlanEditDisabled || consequences.lockPlanDeletionDisabled {
            var plans = lockPlanService.loadPlans()
            plans = plans.map { plan in
                var updated = plan
                if consequences.lockPlanEditDisabled || consequences.lockPlanDeletionDisabled {
                    updated.isEditable = false
                    updated.consequencePolicy = consequences
                }
                return updated
            }
            lockPlanService.savePlans(plans)
        }
        
        if let extraMinutes = consequences.extraLockMinutes, extraMinutes > 0 {
            await sessionService.extendActiveSession(byMinutes: extraMinutes)
        }
        
        if consequences.lockPlanEditDisabled || consequences.lockPlanDeletionDisabled || (consequences.extraLockMinutes ?? 0) > 0 {
            appGroupStorage.setShieldState(
                ShieldState(
                    reason: .contractPenaltyActive,
                    sessionId: contract.sessionId
                )
            )
        }
    }
}
