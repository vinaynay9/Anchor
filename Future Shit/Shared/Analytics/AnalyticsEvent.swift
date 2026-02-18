import Foundation

public enum AnalyticsEvent: String, Codable, CaseIterable {
    case shieldHit = "shield_hit"
    case pledgeCompleted = "pledge_completed"
    case emergencyUnanchorUsed = "emergency_unanchor_used"
    case profileViewed = "profile_viewed"
    case challengeCreated = "challenge_created"
    case challengeCompleted = "challenge_completed"
    case challengeConceded = "challenge_conceded"
    case inviteSent = "invite_sent"
    case inviteAccepted = "invite_accepted"
    case proofSubmitted = "proof_submitted"
    case appOpened = "app_opened"
    case anchorStateChanged = "anchor_state_changed"
}
