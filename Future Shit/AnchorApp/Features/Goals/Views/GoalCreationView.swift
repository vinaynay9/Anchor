import SwiftUI

struct GoalCreationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalsViewModel = GoalViewModel()
    @State private var goalName: String = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: Theme.spacing3) {
                // Title
                Text("Name Your Daily Habit")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.spacing2)
                    .padding(.top, Theme.spacing3)
                
                // Text Field
                TextField("e.g., Complete morning workout", text: $goalName)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(Theme.spacing2)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(Theme.cornerRadiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(
                                isTextFieldFocused ? AppColors.anchorAccent : AppColors.textSecondary.opacity(0.3),
                                lineWidth: isTextFieldFocused ? 2 : 1
                            )
                    )
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, Theme.spacing2)
                    .padding(.top, Theme.spacing2)
                
                // Example goals
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    Text("Examples:")
                        .font(AppTypography.captionBold)
                        .foregroundColor(AppColors.textSecondary)
                    
                    ForEach(["Complete morning workout", "Read for 30 minutes", "Finish work project"], id: \.self) { example in
                        Button(action: {
                            goalName = example
                        }) {
                            HStack {
                                Text(example)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.anchorAccent)
                                Spacer()
                            }
                            .padding(.vertical, Theme.spacing)
                            .padding(.horizontal, Theme.spacing2)
                            .background(AppColors.anchorLavender.opacity(0.1))
                            .cornerRadius(Theme.cornerRadius)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.spacing2)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    saveGoal()
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                                .padding(.trailing, Theme.spacing)
                        }
                        Text("Save Goal")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                .padding(.horizontal, Theme.spacing2)
                .padding(.bottom, Theme.spacing3)
            }
        }
        .navigationTitle("New Goal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func saveGoal() {
        guard !goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSaving = true
        goalsViewModel.addGoal(goalName)
        
        // Post notification for updates
        NotificationCenter.default.post(name: .goalsUpdated, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
}
