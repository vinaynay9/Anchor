import SwiftUI

struct DailyReflectionView: View {
    @StateObject private var viewModel = DailyReflectionViewModel()
    @State private var submitCheckmarkScale: CGFloat = 0.0
    @State private var goalCheckmarkScales: [String: CGFloat] = [:]
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    titleSection
                        .padding(.top, 20)
                    
                    // Glassmorphism Card
                    reflectionCard
                        .padding(.horizontal, 20)
                    
                    // Submit Button
                    submitButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            
            // Toast Overlay
            if viewModel.showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.showCheckmark) { show in
            if show {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    submitCheckmarkScale = 1.0
                }
            }
        }
        .onChange(of: viewModel.checkedGoals) { goals in
            // Animate checkmarks for newly checked goals
            for goal in goals {
                if goalCheckmarkScales[goal] == nil || goalCheckmarkScales[goal] == 0.0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        goalCheckmarkScales[goal] = 1.0
                    }
                }
            }
            // Reset scales for unchecked goals
            for (goal, _) in goalCheckmarkScales {
                if !goals.contains(goal) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        goalCheckmarkScales[goal] = 0.0
                    }
                }
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Daily Reflection")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Take a moment to reflect on your day")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Reflection Card
    private var reflectionCard: some View {
        VStack(spacing: 24) {
            // Mood Picker
            moodPickerSection
            
            Divider()
                .background(AppColors.textSecondary.opacity(0.2))
            
            // Reflection Text Input
            reflectionTextSection
            
            Divider()
                .background(AppColors.textSecondary.opacity(0.2))
            
            // Goals Checkboxes
            goalsSection
        }
        .padding(24)
        .background(
            // Glassmorphism effect
            ZStack {
                // Base background with blur
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.secondaryBackground.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.accent.opacity(0.1),
                                        AppColors.accentLight.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .blur(radius: 10)
                
                // Glass overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.accentLight.opacity(0.4),
                            AppColors.accent.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: AppColors.accent.opacity(0.2), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Mood Picker
    private var moodPickerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How are you feeling?")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 16) {
                ForEach(viewModel.moods, id: \.self) { mood in
                    moodButton(mood: mood)
                }
            }
        }
    }
    
    private func moodButton(mood: String) -> some View {
        Button(action: {
            viewModel.selectMood(mood)
        }) {
            Text(mood)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            viewModel.selectedMood == mood
                                ? AppColors.accent.opacity(0.2)
                                : Color.clear
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            viewModel.selectedMood == mood
                                ? AppColors.accentLight
                                : AppColors.textSecondary.opacity(0.3),
                            lineWidth: viewModel.selectedMood == mood ? 3 : 2
                        )
                )
                .shadow(
                    color: viewModel.selectedMood == mood
                        ? AppColors.accent.opacity(0.6)
                        : Color.clear,
                    radius: viewModel.selectedMood == mood ? 12 : 0
                )
                .scaleEffect(viewModel.selectedMood == mood ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.selectedMood)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Reflection Text Input
    private var reflectionTextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflection")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            ZStack(alignment: .topLeading) {
                if viewModel.reflectionText.isEmpty {
                    Text("Anything on your mind today?")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $viewModel.reflectionText)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.accentLight.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.accentLight.opacity(0.3), lineWidth: 1.5)
                    )
            }
        }
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Goals")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(viewModel.goals, id: \.self) { goal in
                    goalCheckbox(goal: goal)
                }
            }
        }
    }
    
    private func goalCheckbox(goal: String) -> some View {
        Button(action: {
            viewModel.toggleGoal(goal)
        }) {
            HStack(spacing: 16) {
                // Custom Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            viewModel.checkedGoals.contains(goal)
                                ? AppColors.accent
                                : Color.clear
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    viewModel.checkedGoals.contains(goal)
                                        ? AppColors.accentLight
                                        : AppColors.accent.opacity(0.5),
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: viewModel.checkedGoals.contains(goal)
                                ? AppColors.accent.opacity(0.4)
                                : Color.clear,
                            radius: 6
                        )
                    
                    if viewModel.checkedGoals.contains(goal) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .scaleEffect(goalCheckmarkScales[goal] ?? 1.0)
                    }
                }
                .scaleEffect(viewModel.checkedGoals.contains(goal) ? 1.1 : 1.0)
                
                // Goal Text
                Text(goal)
                    .font(AppTypography.body)
                    .foregroundColor(
                        viewModel.checkedGoals.contains(goal)
                            ? AppColors.textPrimary
                            : AppColors.textSecondary
                    )
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            viewModel.submitReflection()
        }) {
            HStack {
                if viewModel.showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .scaleEffect(submitCheckmarkScale)
                } else {
                    Text("Submit Reflection")
                        .font(AppTypography.bodyBold)
                }
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.accent,
                        AppColors.accentLight
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: AppColors.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.accentLight.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.showCheckmark)
    }
    
    // MARK: - Toast View
    private var toastView: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)
                
                Text("Reflection saved!")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.accentLight.opacity(0.3), lineWidth: 1)
            )
            .padding(.top, 60)
            
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showToast)
        .onChange(of: viewModel.showToast) { show in
            if show {
                // Auto-dismiss toast after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        viewModel.showToast = false
                    }
                }
            }
        }
    }
}

#Preview {
    DailyReflectionView()
}

