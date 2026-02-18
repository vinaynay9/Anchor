import Foundation
import Shared

// MARK: - Service Rewrite Decision
// QuorumService is NEW. It replaces single-partner unlock with 51% group unlock logic.

protocol QuorumServiceProtocol {
    func loadQuorumState(sessionId: UUID) -> QuorumState?
    func initializeQuorum(sessionId: UUID, participantIds: [UUID]) -> QuorumState
    func recordVote(sessionId: UUID, voterId: UUID, approve: Bool) -> QuorumState
}

final class QuorumService: QuorumServiceProtocol {
    static let shared = QuorumService()
    
    private let appGroupStorage = AppGroupStorage.shared
    private let sessionService: SessionServiceProtocol
    
    init(sessionService: SessionServiceProtocol = SessionService.shared) {
        self.sessionService = sessionService
    }
    
    func loadQuorumState(sessionId: UUID) -> QuorumState? {
        appGroupStorage.getQuorumState(sessionId: sessionId)
    }
    
    func initializeQuorum(sessionId: UUID, participantIds: [UUID]) -> QuorumState {
        let required = max(1, Int(ceil(Double(participantIds.count) * 0.51)))
        let state = QuorumState(
            participantIds: participantIds,
            approvedIds: [],
            deniedIds: [],
            requiredApprovalCount: required
        )
        appGroupStorage.setQuorumState(state, sessionId: sessionId)
        appGroupStorage.setShieldState(
            ShieldState(
                reason: .waitingForQuorum,
                sessionId: sessionId,
                quorumState: state
            )
        )
        return state
    }
    
    func recordVote(sessionId: UUID, voterId: UUID, approve: Bool) -> QuorumState {
        var state = loadQuorumState(sessionId: sessionId) ?? initializeQuorum(sessionId: sessionId, participantIds: [])
        
        if approve {
            state.approvedIds.insert(voterId)
            state.deniedIds.remove(voterId)
        } else {
            state.deniedIds.insert(voterId)
            state.approvedIds.remove(voterId)
        }
        
        let updated = QuorumState(
            participantIds: state.participantIds,
            approvedIds: state.approvedIds,
            deniedIds: state.deniedIds,
            requiredApprovalCount: state.requiredApprovalCount,
            updatedAt: Date()
        )
        
        appGroupStorage.setQuorumState(updated, sessionId: sessionId)
        appGroupStorage.setShieldState(
            ShieldState(
                reason: updated.hasReachedQuorum ? .unlockApproved : .waitingForQuorum,
                sessionId: sessionId,
                quorumState: updated
            )
        )
        
        if updated.hasReachedQuorum {
            Task {
                await sessionService.handleQuorumReached(sessionId: sessionId)
            }
        }
        
        return updated
    }
}

