import Foundation

public struct RemoteAppConfig: Codable {
    public let awsRegion: String?
    public let apiBaseURLOverride: String?
    public let updatedAtISO: String?

    public init(
        awsRegion: String? = nil,
        apiBaseURLOverride: String? = nil,
        updatedAtISO: String? = nil
    ) {
        self.awsRegion = awsRegion
        self.apiBaseURLOverride = apiBaseURLOverride
        self.updatedAtISO = updatedAtISO
    }
}
