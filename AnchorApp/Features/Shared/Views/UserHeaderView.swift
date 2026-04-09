import SwiftUI
import Shared

// MARK: - UserHeaderView
// Subtle custom nav bar shown at top of Session (tab 0) and Goals (tab 1).
// Left: initials circle + first name. Right: streak flame count.

struct UserHeaderView: View {
    let firstName: String
    let initials: String
    let streak: Int

    var body: some View {
        HStack(spacing: 10) {
            // Initials avatar
            Circle()
                .fill(LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 34, height: 34)
                .overlay(
                    Text(initials)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.onPrimary)
                )

            Text(firstName)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            // Streak badge
            if streak > 0 {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text("\(streak)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule().stroke(AppColors.accent.opacity(0.30), lineWidth: 1)
                        )
                )
            } else {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text("0")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(AppColors.surface.opacity(0.40))
                        .overlay(
                            Capsule().stroke(AppColors.border.opacity(0.30), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, Theme.spacing3)
        .padding(.top, 52) // below status bar
        .padding(.bottom, Theme.spacing)
        .background(AppColors.brandBackgroundDark.opacity(0.95))
    }
}

// MARK: - UserHeaderViewModel (lightweight, shared)

@MainActor
final class UserHeaderViewModel: ObservableObject {
    @Published var firstName: String = "there"
    @Published var initials: String = "?"
    @Published var streak: Int = 0

    private let storage = AppGroupStorage.shared
    private let aggregateService = AggregateService.shared

    func load() {
        let personal = storage.getPersonalInfo()
        if let first = personal?.firstName, !first.isEmpty {
            firstName = first
            let lastInitial = personal?.lastName.first.map(String.init) ?? ""
            initials = (String(first.prefix(1)) + lastInitial).uppercased()
        } else if let profile = storage.getProfile(), !profile.displayName.isEmpty {
            firstName = profile.displayName.components(separatedBy: " ").first ?? profile.displayName
            initials = String(profile.displayName.prefix(2)).uppercased()
        }
        streak = aggregateService.currentStreak()
    }
}
