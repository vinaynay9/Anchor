import Foundation

public struct RemoteAppConfig: Codable {
    public let googleClientID: String?
    public let googleReverseClientID: String?
    public let awsRegion: String?
    public let cognitoIdentityPoolId: String?
    public let apiBaseURLOverride: String?
    public let updatedAtISO: String?

    public init(
        googleClientID: String? = nil,
        googleReverseClientID: String? = nil,
        awsRegion: String? = nil,
        cognitoIdentityPoolId: String? = nil,
        apiBaseURLOverride: String? = nil,
        updatedAtISO: String? = nil
    ) {
        self.googleClientID = googleClientID
        self.googleReverseClientID = googleReverseClientID
        self.awsRegion = awsRegion
        self.cognitoIdentityPoolId = cognitoIdentityPoolId
        self.apiBaseURLOverride = apiBaseURLOverride
        self.updatedAtISO = updatedAtISO
    }
}
