import Foundation
import Shared

// MARK: - Lock Schedule View Model
// Lets the user pick the nightly lock time (default midnight).
// Persists a DailyAnchorTime to AppGroupStorage so DailyAnchorService
// and DeviceActivity can pick it up.

@MainActor
final class LockScheduleViewModel: ObservableObject {

    // MARK: - Published State

    /// The selected lock hour (0–23, 24h clock).
    @Published var selectedHour: Int = 0    // midnight
    /// The selected lock minute (always 0 for now — whole-hour steps).
    @Published var selectedMinute: Int = 0

    // MARK: - Allowed range
    // 20:00 (8 PM) through 04:00 (4 AM) the next day.
    // Represented as an array of (hour, label) tuples for the picker.

    struct PickerRow: Identifiable, Hashable {
        let hour: Int
        let minute: Int
        var id: Int { hour * 60 + minute }

        var displayLabel: String {
            let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let suffix = hour < 12 ? "AM" : "PM"
            if minute == 0 {
                return "\(h12):00 \(suffix)"
            }
            return String(format: "%d:%02d %@", h12, minute, suffix)
        }
    }

    static let allowedRows: [PickerRow] = {
        // 8 PM (20:00) → 4 AM (04:00) next day, in 30-minute steps
        var rows: [PickerRow] = []
        let rawHours: [Int] = [20, 21, 22, 23, 0, 1, 2, 3, 4]
        for h in rawHours {
            rows.append(PickerRow(hour: h, minute: 0))
            if h != 4 { rows.append(PickerRow(hour: h, minute: 30)) }
        }
        return rows
    }()

    // MARK: - Selected picker row binding

    var selectedRow: PickerRow {
        Self.allowedRows.first { $0.hour == selectedHour && $0.minute == selectedMinute }
            ?? PickerRow(hour: 0, minute: 0)
    }

    func select(row: PickerRow) {
        selectedHour   = row.hour
        selectedMinute = row.minute
    }

    // MARK: - Contextual explanation

    /// Dynamic explanation shown below the picker.
    var explanationText: String {
        let row    = selectedRow
        let label  = row.displayLabel
        let isEveningBefore = selectedHour >= 20 // 8 PM–11:30 PM

        let base = "Your apps will be locked starting at \(label) each day. Complete your goals to unlock them."

        if isEveningBefore {
            return base + "\n\nThe lock starts the evening before, so your apps will be locked when you wake up."
        }
        return base
    }

    var isEveningLock: Bool { selectedHour >= 20 }

    // MARK: - Save

    func save() {
        let anchorTime = DailyAnchorTime(hour: selectedHour, minute: selectedMinute)
        AppGroupStorage.shared.setDailyAnchorTime(anchorTime)
        LoggerService.shared.logInfo(
            "Lock schedule saved: \(selectedHour):\(String(format: "%02d", selectedMinute))",
            category: "Onboarding"
        )
    }
}
