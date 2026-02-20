import SwiftUI
import FamilyControls

struct SessionSetupView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalsViewModel = GoalViewModel()
    @State private var showActivityPicker = false
    @State private var activitySelection = FamilyActivitySelection()
    @State private var hasSelectedApps = false
    @State private var deepAnchor = false
    @State private var showGoalCreation = false
    
    private let activitySelectionService = ActivitySelectionService.shared
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    // Title
                    titleSection
                    
                    // Daily Goals Overview
                    dailyGoalsSection
                    
                    // App Selection Panel
                    appSelectionSection
                    
                    // Anchored Mode Note
                    anchoredModeNoteSection
                    
                    // Optional Settings
                    optionalSettingsSection
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(message: errorMessage)
                    }
                    
                    // Start Session Button
                    startSessionButton
                }
                .padding(Theme.spacing2)
            }
        }
        .navigationTitle("Enter Anchored Mode")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showActivityPicker) {
            ActivityPickerView(selection: $activitySelection)
                .onDisappear {
                    do {
                        try activitySelectionService.saveSelection(activitySelection)
                        hasSelectedApps = !activitySelection.applicationTokens.isEmpty
                    } catch {
                        print("Failed to save activity selection: \(error)")
                    }
                }
        }
        .onAppear {
            goalsViewModel.reload()
            if let existingSelection = activitySelectionService.loadSelection() {
                activitySelection = existingSelection
                hasSelectedApps = !existingSelection.applicationTokens.isEmpty
            }
        }
        .onChange(of: viewModel.activeSession) { session in
            if session != nil {
                dismiss()
            }
        }
        .sheet(isPresented: $showGoalCreation) {
            NavigationStack {
                GoalCreationView()
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        Text("Enter Anchored Mode")
            .font(AppTypography.screenTitle)
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Daily Goals Section
    private var dailyGoalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            HStack {
                Text("Today's Goals")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !goalsViewModel.goals.isEmpty {
                    Text("\(goalsViewModel.getCompletedCount())/\(goalsViewModel.getTotalCount())")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(.horizontal, Theme.spacing2)
            
            if goalsViewModel.goals.isEmpty {
                emptyGoalsCard
            } else {
                goalsOverviewCard
            }
        }
    }
    
    private var emptyGoalsCard: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: "plus.circle")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            Text("No goals set yet")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Button(action: {
                HapticFeedback.selectionChanged()
                showGoalCreation = true
            }) {
                Text("Add Goal")
            }
            .buttonStyle(SecondaryPressableButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacing3)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, Theme.spacing2)
    }
    
    private var goalsOverviewCard: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(goalsViewModel.goals.prefix(3)) { goal in
                GoalRowView(goal: goal) {
                    goalsViewModel.toggleGoal(goal)
                }
            }
            
            if goalsViewModel.goals.count > 3 {
                Text("+ \(goalsViewModel.goals.count - 3) more")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - App Selection Section
    private var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Apps to Block")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            Button(action: {
                HapticFeedback.selectionChanged()
                showActivityPicker = true
            }) {
                HStack {
                    Text(hasSelectedApps ? "Change App Selection" : "Select Apps to Block")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    if hasSelectedApps {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(Theme.spacing2)
                .background(AppColors.surface)
                .cornerRadius(Theme.cornerRadiusMedium)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, Theme.spacing2)
            .buttonStyle(PressableButtonStyle())
            .anchorHover()
        }
    }
    
    // MARK: - Anchored Mode Note
    private var anchoredModeNoteSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            HStack(alignment: .top, spacing: Theme.spacing) {
                Image(systemName: "info.circle")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.accent)
                
                Text("Apps stay locked until you complete all goals.")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.surfaceElevated)
        .cornerRadius(Theme.cornerRadius)
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Optional Settings
    private var optionalSettingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Optional Settings")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            VStack(spacing: Theme.spacing) {
                Toggle(isOn: $deepAnchor) {
                    VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                        Text("Deep Anchor")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Extended lock. No early exits.")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.accent)
            }
            .padding(Theme.spacing2)
            .background(AppColors.surface)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, Theme.spacing2)
        }
    }
    
    // MARK: - Start Session Button
    private var startSessionButton: some View {
        Button(action: {
            Task {
                HapticFeedback.selectionChanged()
                await viewModel.startSession()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                        .padding(.trailing, Theme.spacing)
                }
                Text("Lock & Anchor")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryPressableButtonStyle())
        .disabled(viewModel.isLoading || !hasSelectedApps)
        .opacity(viewModel.isLoading || !hasSelectedApps ? 0.6 : 1.0)
        .padding(.horizontal, Theme.spacing2)
        .padding(.top, Theme.spacing)
    }
    
    // MARK: - Error Banner
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppColors.error)
            Text(message)
                .font(AppTypography.helper)
                .foregroundColor(AppColors.error)
        }
        .padding(Theme.spacing2)
        .background(AppColors.error.opacity(0.1))
        .cornerRadius(Theme.cornerRadius)
        .padding(.horizontal, Theme.spacing2)
    }
}
