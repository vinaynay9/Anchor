import SwiftUI

// MARK: - Onboarding Flow ViewModel
// Minimal persistence layer for the welcome pager.
// The previous splash/pager stage machine was removed when the welcome screen
// was merged into Page 1 of the new OnboardingPagerView.
@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private(set) var hasCompletedOnboarding: Bool = false

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - LockScheduleViewModel
// Moved here from Features/OnboardingSchedule/ViewModels/LockScheduleViewModel.swift
// so it compiles as part of the main AnchorApp target (that file is not in Xcode project).
// Manages the nightly lock-time picker during onboarding.

@MainActor
final class LockScheduleViewModel: ObservableObject {

    @Published var selectedHour: Int = 0    // midnight
    @Published var selectedMinute: Int = 0

    struct PickerRow: Identifiable, Hashable {
        let hour: Int
        let minute: Int
        var id: Int { hour * 60 + minute }

        var displayLabel: String {
            let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let suffix = hour < 12 ? "AM" : "PM"
            if minute == 0 { return "\(h12):00 \(suffix)" }
            return String(format: "%d:%02d %@", h12, minute, suffix)
        }
    }

    static let allowedRows: [PickerRow] = {
        var rows: [PickerRow] = []
        for h in [20, 21, 22, 23, 0, 1, 2, 3, 4] {
            rows.append(PickerRow(hour: h, minute: 0))
            if h != 4 { rows.append(PickerRow(hour: h, minute: 30)) }
        }
        return rows
    }()

    var selectedRow: PickerRow {
        Self.allowedRows.first { $0.hour == selectedHour && $0.minute == selectedMinute }
            ?? PickerRow(hour: 0, minute: 0)
    }

    func select(row: PickerRow) {
        selectedHour   = row.hour
        selectedMinute = row.minute
    }

    var explanationText: String {
        let label = selectedRow.displayLabel
        let base  = "Your apps will be locked starting at \(label) each day. Complete your goals to unlock them."
        if selectedHour >= 20 {
            return base + "\n\nThe lock starts the evening before, so your apps will be locked when you wake up."
        }
        return base
    }

    var isEveningLock: Bool { selectedHour >= 20 }

    func save() {
        let anchorTime = DailyAnchorTime(hour: selectedHour, minute: selectedMinute)
        AppGroupStorage.shared.setDailyAnchorTime(anchorTime)
        LoggerService.shared.logInfo(
            "Lock schedule saved: \(selectedHour):\(String(format: "%02d", selectedMinute))",
            category: "Onboarding"
        )
    }
}
