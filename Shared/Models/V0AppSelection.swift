import Foundation

public struct V0AppSelection: Codable, Hashable {
    public var blockedApplications: [Data]
    public var blockedCategories: [Data]
    public var perGoalUnlockedApplications: [Data]
    /// Base64-encoded ApplicationToken data -> bundleID (best-effort)
    public var applicationTokenBundleIDs: [String: String]

    public init(
        blockedApplications: [Data] = [],
        blockedCategories: [Data] = [],
        perGoalUnlockedApplications: [Data] = [],
        applicationTokenBundleIDs: [String: String] = [:]
    ) {
        self.blockedApplications = blockedApplications
        self.blockedCategories = blockedCategories
        self.perGoalUnlockedApplications = perGoalUnlockedApplications
        self.applicationTokenBundleIDs = applicationTokenBundleIDs
    }
}
