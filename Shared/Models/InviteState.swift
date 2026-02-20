import Foundation

public struct InviteState: Codable, Hashable {
    public let inviterId: String
    public let inviteCode: String
    public let inviteLink: String
    public let inviteCount: Int
    public let lastRefreshAt: Date?

    public init(inviterId: String, inviteCode: String, inviteLink: String, inviteCount: Int, lastRefreshAt: Date?) {
        self.inviterId = inviterId
        self.inviteCode = inviteCode
        self.inviteLink = inviteLink
        self.inviteCount = inviteCount
        self.lastRefreshAt = lastRefreshAt
    }
}

public struct InviteAttribution: Codable, Hashable {
    public let inviterId: String
    public let inviteCode: String
    public let receivedAt: Date

    public init(inviterId: String, inviteCode: String, receivedAt: Date = Date()) {
        self.inviterId = inviterId
        self.inviteCode = inviteCode
        self.receivedAt = receivedAt
    }
}
