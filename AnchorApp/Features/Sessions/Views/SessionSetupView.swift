import SwiftUI
import FamilyControls

struct SessionSetupView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalService = GoalService.shared
    @State private var goals: [Goal] = []
    @State private var mockFriends: [MockFriend] = [
        MockFriend(id: UUID().uuidString, name: "Alice"),
        MockFriend(id: UUID().uuidString, name: "Bob"),
        MockFriend(id: UUID().uuidString, name: "Charlie")
    ]
    @State private var showActivityPicker = false
    @State private var activitySelection = FamilyActivitySelection()
    @State private var hasSelectedApps = false
    @State private var requirePhotoProof = false
    @State private var allowFriendApproval = true
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
                    
                    // Accountability Note
                    accountabilityNoteSection
                    
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
        .navigationTitle("Start Your Daily Session")
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
            loadGoals()
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
        Text("Start Your Daily Session")
            .font(AppTypography.largeTitle)
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Daily Goals Section
    private var dailyGoalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            HStack {
                Text("Today's Goals")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !goals.isEmpty {
                    Text("\(goalService.getCompletedCount())/\(goalService.getTotalCount())")
                        .font(AppTypography.captionBold)
                        .foregroundColor(AppColors.anchorAccent)
                }
            }
            .padding(.horizontal, Theme.spacing2)
            
            if goals.isEmpty {
                emptyGoalsCard
            } else {
                goalsOverviewCard
            }
        }
    }
    
    private var emptyGoalsCard: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            Text("No goals set yet")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Button(action: {
                showGoalCreation = true
            }) {
                Text("Add Goal")
                    .font(AppTypography.captionBold)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacing3)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
        .padding(.horizontal, Theme.spacing2)
    }
    
    private var goalsOverviewCard: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(goals.prefix(3)) { goal in
                GoalRowView(goal: goal) {
                    goalService.toggleGoal(goal)
                    loadGoals()
                }
            }
            
            if goals.count > 3 {
                Text("+ \(goals.count - 3) more")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.anchorLavender.opacity(0.3),
                            AppColors.anchorAccent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - App Selection Section
    private var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Apps to Block")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            Button(action: {
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
                .background(AppColors.secondaryBackground)
                .cornerRadius(Theme.cornerRadiusMedium)
            }
            .padding(.horizontal, Theme.spacing2)
        }
    }
    
    // MARK: - Accountability Note
    private var accountabilityNoteSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            HStack(alignment: .top, spacing: Theme.spacing) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.anchorAccent)
                
                Text("Apps stay blocked until you complete all goals or send an unlock request with proof.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.anchorLavender.opacity(0.1))
        .cornerRadius(Theme.cornerRadius)
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Optional Settings
    private var optionalSettingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Optional Settings")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            VStack(spacing: Theme.spacing) {
                Toggle(isOn: $requirePhotoProof) {
                    VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                        Text("Require Photo Proof")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Unlock requests must include photo evidence")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.anchorAccent)
                
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                
                Toggle(isOn: $allowFriendApproval) {
                    VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                        Text("Allow Friends to Approve Unlocks")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Friends can approve unlock requests")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.anchorAccent)
            }
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
            .padding(.horizontal, Theme.spacing2)
        }
    }
    
    // MARK: - Start Session Button
    private var startSessionButton: some View {
        Button(action: {
            Task {
                await viewModel.startSession()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                        .padding(.trailing, Theme.spacing)
                }
                Text("Start Session")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isLoading || !hasSelectedApps)
        .padding(.horizontal, Theme.spacing2)
        .padding(.top, Theme.spacing)
    }
    
    // MARK: - Error Banner
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppColors.error)
            Text(message)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.error)
        }
        .padding(Theme.spacing2)
        .background(AppColors.error.opacity(0.1))
        .cornerRadius(Theme.cornerRadius)
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Helper Methods
    private func loadGoals() {
        goals = goalService.loadGoals()
    }
}

// Mock friend struct for placeholder implementation
struct MockFriend: Identifiable {
    let id: String
    let name: String
}

