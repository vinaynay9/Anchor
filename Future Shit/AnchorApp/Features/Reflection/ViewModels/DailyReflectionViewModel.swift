import Foundation
import SwiftUI
import Combine

@MainActor
class DailyReflectionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedMood: String? = nil
    @Published var reflectionText: String = ""
    @Published var checkedGoals: Set<String> = []
    @Published var showCheckmark: Bool = false
    
    // MARK: - AppStorage
    @AppStorage("dailyReflection_mood") private var storedMood: String = ""
    @AppStorage("dailyReflection_text") private var storedText: String = ""
    @AppStorage("dailyReflection_goals") private var storedGoals: String = ""
    
    // MARK: - Constants
    let moods = ["😩", "😕", "🙂", "😄", "🤩"]
    let goals = [
        "Stayed focused",
        "Completed priority tasks",
        "Minimized distractions"
    ]
    
    // MARK: - Initialization
    init() {
        loadStoredData()
    }
    
    // MARK: - Actions
    func selectMood(_ mood: String) {
        selectedMood = mood
        storedMood = mood
        triggerHapticFeedback(style: .light)
    }
    
    func toggleGoal(_ goal: String) {
        if checkedGoals.contains(goal) {
            checkedGoals.remove(goal)
        } else {
            checkedGoals.insert(goal)
            triggerHapticFeedback(style: .light)
        }
        saveGoals()
    }
    
    func submitReflection() {
        // Save to AppStorage
        storedText = reflectionText
        saveGoals()
        
        // Trigger animations
        showCheckmark = true
        triggerHapticFeedback(style: .medium)
        
        // Show toast after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ToastManager.shared.show("Reflection saved!")
        }
        
        // Reset form after animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.resetForm()
        }
    }
    
    func resetForm() {
        selectedMood = nil
        reflectionText = ""
        checkedGoals = []
        showCheckmark = false
        
        // Clear stored data
        storedMood = ""
        storedText = ""
        storedGoals = ""
    }
    
    // MARK: - Private Methods
    private func loadStoredData() {
        if !storedMood.isEmpty {
            selectedMood = storedMood
        }
        reflectionText = storedText
        if !storedGoals.isEmpty {
            checkedGoals = Set(storedGoals.components(separatedBy: ","))
        }
    }
    
    private func saveGoals() {
        storedGoals = Array(checkedGoals).joined(separator: ",")
    }
    
    private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

