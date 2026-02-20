import SwiftUI

struct CreateSessionView: View {
    @StateObject private var viewModel = CreateSessionViewModel()
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    // Header
                    gradientHeader
                        .padding(.top, Theme.spacing2)
                    
                    // Duration picker card
                    durationPickerCard
                    
                    // Start session button
                    startSessionButton
                        .padding(.bottom, Theme.spacing4)
                }
                .padding(.horizontal, Theme.spacing2)
            }
        }
    }
    
    // MARK: - Gradient Header
    private var gradientHeader: some View {
        VStack(spacing: Theme.spacing) {
            Text("Enter Anchored Mode")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Lock selected apps until your goals are complete.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing3)
        .background(AppColors.surface)
        .cornerRadius(AppLayout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Duration Picker Card
    private var durationPickerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.durationOptions, id: \.self) { duration in
                    durationButton(duration: duration)
                }
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(AppLayout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func durationButton(duration: Int) -> some View {
        Button(action: {
            HapticFeedback.selectionChanged()
            viewModel.selectedDuration = duration
        }) {
            VStack(spacing: 4) {
                Text("\(duration)")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(
                        viewModel.selectedDuration == duration
                            ? AppColors.textPrimary
                            : AppColors.textSecondary
                    )
                
                Text("min")
                    .font(AppTypography.caption)
                    .foregroundColor(
                        viewModel.selectedDuration == duration
                            ? AppColors.textSecondary
                            : AppColors.textSecondary.opacity(0.6)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.selectedDuration == duration
                    ? AppColors.accent.opacity(0.12)
                    : Color.clear
            )
            .cornerRadius(AppLayout.chipCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                    .stroke(
                        viewModel.selectedDuration == duration
                            ? AppColors.border.opacity(0.6)
                            : AppColors.border.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    // MARK: - Start Session Button
    private var startSessionButton: some View {
        Button(action: {
            HapticFeedback.selectionChanged()
            viewModel.startSession()
        }) {
            HStack {
                Spacer()
                Text("Lock & Anchor")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.onPrimary)
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(PrimaryPressableButtonStyle())
    }
}

#Preview {
    CreateSessionView()
}
