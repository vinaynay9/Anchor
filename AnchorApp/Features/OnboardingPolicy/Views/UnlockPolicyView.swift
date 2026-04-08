import SwiftUI
import Shared

// MARK: - Reward Rules View
// Onboarding step 2: configure the unlock incentive.
//   Q1. How many goals to earn a break?
//   Q2. How much time per break?

struct UnlockPolicyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var viewModel: UnlockPolicyViewModel
    @State private var showContent = false
    @FocusState private var customFieldFocused: Bool

    let onNext: (UnlockPolicyConfig) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)
                    header
                    Spacer().frame(height: Theme.spacing5)
                    question1
                    Spacer().frame(height: Theme.spacing4)
                    question2
                    Spacer().frame(height: Theme.spacing4)
                    summaryCard
                    Spacer().frame(height: 120)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .onTapGesture { customFieldFocused = false }

            stickyFooter
        }
        .ignoresSafeArea()
        .onAppear {
            guard !showContent else { return }
            if reduceMotion {
                showContent = true
            } else {
                withAnimation(AppMotion.gentleSpring.delay(0.06)) { showContent = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Reward Rules")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Decide how you earn screen time.")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.spacing4)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 14)
    }

    // MARK: - Question 1: goals per break

    private var question1: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            sectionLabel("How many goals to earn a break?")

            // 2×2 grid of option chips
            let cols = [GridItem(.flexible(), spacing: Theme.spacing), GridItem(.flexible(), spacing: Theme.spacing)]
            LazyVGrid(columns: cols, spacing: Theme.spacing) {
                ForEach(UnlockPolicyViewModel.GoalsThreshold.allCases, id: \.self) { option in
                    ThresholdChip(
                        label: option.displayName,
                        isSelected: viewModel.selectedThreshold == option,
                        action: {
                            withAnimation(AppMotion.snappy) { viewModel.selectedThreshold = option }
                        }
                    )
                }
            }

            // "All goals" note
            if viewModel.selectedThreshold == .all {
                InfoNote(text: "Complete all your goals to fully unlock your apps for the rest of the day.")
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
        .animation(AppMotion.standard, value: viewModel.selectedThreshold)
    }

    // MARK: - Question 2: minutes per break

    private var question2: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            sectionLabel("How much time per break?")

            let cols = [
                GridItem(.flexible(), spacing: Theme.spacing),
                GridItem(.flexible(), spacing: Theme.spacing),
                GridItem(.flexible(), spacing: Theme.spacing),
                GridItem(.flexible(), spacing: Theme.spacing),
            ]
            LazyVGrid(columns: cols, spacing: Theme.spacing) {
                // Standard options
                ForEach(UnlockPolicyViewModel.MinutesOption.standardCases, id: \.self) { option in
                    ThresholdChip(
                        label: option.displayName,
                        isSelected: viewModel.selectedMinutes == option,
                        action: {
                            withAnimation(AppMotion.snappy) { viewModel.selectedMinutes = option }
                        }
                    )
                }
                // Custom chip
                ThresholdChip(
                    label: "Custom",
                    isSelected: viewModel.isCustomSelected,
                    action: {
                        withAnimation(AppMotion.snappy) {
                            viewModel.selectedMinutes = .custom(viewModel.customMinutes)
                        }
                    }
                )
            }

            // Custom input
            if viewModel.isCustomSelected {
                HStack(spacing: Theme.spacing2) {
                    Text("Minutes:")
                        .font(AppTypography.helper)
                        .foregroundColor(AppColors.textSecondary)

                    TextField("e.g. 20", value: $viewModel.customMinutes, format: .number)
                        .keyboardType(.numberPad)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .focused($customFieldFocused)
                        .padding(.vertical, 8)
                        .padding(.horizontal, Theme.spacing2)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                        .stroke(AppColors.accent.opacity(0.50), lineWidth: 1)
                                )
                        )
                        .frame(width: 100)
                        .onChange(of: viewModel.customMinutes) { v in
                            viewModel.selectedMinutes = .custom(v)
                        }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
        .animation(AppMotion.standard, value: viewModel.isCustomSelected)
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.accent)

            Text(viewModel.summaryText)
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacing2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.accent.opacity(0.30), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
        .animation(AppMotion.standard, value: viewModel.summaryText)
    }

    // MARK: - Sticky footer

    private var stickyFooter: some View {
        Button {
            customFieldFocused = false
            onNext(viewModel.buildConfig())
        } label: {
            Text("Continue")
                .font(AppTypography.button)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(continueBackground)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!viewModel.isValid)
        .padding(.horizontal, Theme.spacing3)
        .padding(.vertical, Theme.spacing2)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [AppColors.brandBackgroundDark.opacity(0), AppColors.brandBackgroundDark],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var continueBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(viewModel.isValid ? AppColors.accent : AppColors.accent.opacity(0.30))
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.12), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
        }
        .shadow(
            color: viewModel.isValid ? AppColors.accent.opacity(0.40) : .clear,
            radius: 18, x: 0, y: 8
        )
        .animation(AppMotion.snappy, value: viewModel.isValid)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.sectionHeader)
            .foregroundColor(AppColors.textPrimary)
    }
}

// MARK: - Reusable Chips

private struct ThresholdChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.helper)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacing + 2)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .fill(isSelected ? AppColors.accent.opacity(0.90) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                .stroke(
                                    isSelected ? AppColors.accent : AppColors.border.opacity(0.60),
                                    lineWidth: isSelected ? 0 : 1
                                )
                        )
                )
                .shadow(
                    color: isSelected ? AppColors.accent.opacity(0.30) : .clear,
                    radius: 8, x: 0, y: 4
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct InfoNote: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.accent.opacity(0.80))
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacing)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                .fill(AppColors.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                        .stroke(AppColors.accent.opacity(0.25), lineWidth: 0.75)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    UnlockPolicyView(viewModel: UnlockPolicyViewModel(), onNext: { _ in })
}
