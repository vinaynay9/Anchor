import ManagedSettings
import ManagedSettingsUI
import Shared
import UIKit
import os.log

// MARK: - Shield Configuration Extension
// Loaded by the system via NSExtensionPrincipalClass.

private let shieldLog = OSLog(subsystem: "com.vinay.Anchor", category: "ShieldExtension")

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let storage = AppGroupStorage.shared
        let shieldState = storage.getShieldState()

        let title: String
        let subtitle: String
        let primaryLabel: ShieldConfiguration.Label?
        let secondaryLabel: ShieldConfiguration.Label?
        let titleColor = UIColor(AppColors.onPrimary)
        let subtitleColor = UIColor(AppColors.onPrimarySecondary)

        if let shieldState = shieldState {
            switch shieldState.reason {
            case .waitingForQuorum:
                title = "Unlock pending."
                subtitle = "Waiting for group quorum to approve."
                primaryLabel = .init(text: "Open Anchor", color: titleColor)
                secondaryLabel = .init(text: "Return to Anchor", color: subtitleColor)
            case .goalNotApproved:
                title = "Goals incomplete."
                subtitle = "Complete your goals before unlocking."
                primaryLabel = .init(text: "Open Anchor", color: titleColor)
                secondaryLabel = .init(text: "Return to Anchor", color: subtitleColor)
            case .contractPenaltyActive:
                title = "Contract penalty active."
                subtitle = "This lock is enforced by a social contract."
                primaryLabel = .init(text: "Open Anchor", color: titleColor)
                secondaryLabel = .init(text: "Return to Anchor", color: subtitleColor)
            case .unlockApproved:
                title = "Unlock approved."
                subtitle = "Your unlock request has been approved."
                primaryLabel = .init(text: "Open Anchor", color: titleColor)
                secondaryLabel = .init(text: "Return to Anchor", color: subtitleColor)
            case .activeLock, .free:
                title = "You're anchored."
                subtitle = "This app is blocked during your anchor window."
                primaryLabel = .init(text: "Request Unlock", color: titleColor)
                secondaryLabel = .init(text: "Open Anchor", color: subtitleColor)
            }
        } else {
            title = "You're anchored."
            subtitle = "This app is blocked during your anchor window."
            primaryLabel = .init(text: "Request Unlock", color: titleColor)
            secondaryLabel = .init(text: "Open Anchor", color: subtitleColor)
        }

        os_log("Shield configuration built - %{public}@", log: shieldLog, type: .info, title)

        return ShieldConfiguration(
            backgroundColor: UIColor(AppColors.shieldBackground),
            icon: nil,
            title: ShieldConfiguration.Label(text: title, color: titleColor),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: subtitleColor),
            primaryButtonLabel: primaryLabel,
            secondaryButtonLabel: secondaryLabel
        )
    }
}
