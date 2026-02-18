import ManagedSettings
import ManagedSettingsUI
import Shared
import UIKit

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
        let goals = storage.getV0Goals()
        let completed = storage.getV0DailyState().completedGoalIDsToday.count

        let title = V0ShieldMessages.lockedTitle
        let subtitle = V0ShieldMessages.lockedSubtitle
        let progress = goals.isEmpty ? nil : "Completed \(completed)/\(goals.count) today"

        let titleColor = UIColor(AppColors.textPrimary)
        let subtitleColor = UIColor(AppColors.textSecondary)

        return ShieldConfiguration(
            backgroundColor: UIColor(AppColors.background),
            icon: nil,
            title: ShieldConfiguration.Label(text: title, color: titleColor),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: subtitleColor),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Open Anchor", color: titleColor),
            secondaryButtonLabel: progress.map { ShieldConfiguration.Label(text: $0, color: subtitleColor) }
        )
    }
}
