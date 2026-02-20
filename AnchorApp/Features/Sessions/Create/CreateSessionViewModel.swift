import SwiftUI
import Foundation
import Shared

@MainActor
class CreateSessionViewModel: ObservableObject {
    // Duration options in minutes
    let durationOptions: [Int] = [15, 30, 45, 60, 90, 120]
    
    @Published var selectedDuration: Int = 30
    @Published var selectedCategories: Set<AppCategory> = []
    @Published var isScheduled: Bool = false
    @Published var scheduleWeekdays: Set<Int> = [] // 1=Sunday, 2=Monday, ..., 7=Saturday
    @Published var scheduleStartTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var scheduleEndTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Available categories
    let availableCategories = AppCategory.allCases
    
    // Weekday options for scheduling
    let weekdayOptions: [(value: Int, name: String)] = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]
    
    func toggleCategory(_ category: AppCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    func toggleWeekday(_ weekday: Int) {
        if scheduleWeekdays.contains(weekday) {
            scheduleWeekdays.remove(weekday)
        } else {
            scheduleWeekdays.insert(weekday)
        }
    }
    
    func createSchedule() -> LockSessionSchedule? {
        guard isScheduled, !scheduleWeekdays.isEmpty else {
            return nil
        }
        
        let startTime = TimeOfDay.from(scheduleStartTime)
        let endTime = TimeOfDay.from(scheduleEndTime)
        
        return LockSessionSchedule(
            weekdays: scheduleWeekdays,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: selectedDuration
        )
    }
    
    func startSession() {
        print("[CreateSessionViewModel] Starting session with duration: \(selectedDuration) minutes, categories: \(selectedCategories.map { $0.displayName })")
        if isScheduled {
            print("   - Scheduled: \(scheduleWeekdays), \(scheduleStartTime) - \(scheduleEndTime)")
        }
    }
}
