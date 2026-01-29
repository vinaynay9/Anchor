import ManagedSettings
import Foundation
import os.log

private let shieldActionLog = OSLog(
    subsystem: "com.vinay.Anchor",
    category: "ShieldAction"
)

final class ShieldActionExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            os_log("Shield action: primary button", log: shieldActionLog, type: .info)

        case .secondaryButtonPressed:
            os_log("Shield action: secondary button", log: shieldActionLog, type: .info)

        @unknown default:
            os_log("Shield action: unknown", log: shieldActionLog, type: .info)
        }

        completionHandler(.close)
    }
}
