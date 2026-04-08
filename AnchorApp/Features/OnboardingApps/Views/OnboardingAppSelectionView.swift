import SwiftUI
import FamilyControls

// MARK: - Onboarding App Selection View
// Final onboarding step: pick apps to block.
// Requests FamilyControls auth, shows recommended categories,
// opens FamilyActivityPicker, then applies initial shield on Continue.

struct OnboardingAppSelectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var viewModel: OnboardingAppSelectionViewModel
    @State private var showBlockedPicker = false
    @State private var showContent = false
    @State private var isSaving = false

    let onFinish: () -> Void

    // Categories highlighted as recommended
    private let recommendedLabels = ["Social Media", "Games", "Entertainment"]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)
                    header
                    Spacer().frame(height: Theme.spacing4)
                    recommendedCard
                    Spacer().frame(height: Theme.spacing3)
                    selectionCard
                    Spacer().frame(height: Theme.spacing3)
                    if let error = viewModel.authorizationError {
                        authErrorBanner(error)
                        Spacer().frame(height: Theme.spacing2)
                    }
                    Spacer().frame(height: 120)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            stickyFooter
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showBlockedPicker) {
            FamilyActivityPickerWrapper(selection: $viewModel.blockedSelection)
        }
        .task {
            await viewModel.loadState()
            await viewModel.requestAuthorizationIfNeeded()
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
            Text("Choose Apps to Block")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Block distracting apps during your focus sessions.")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing4)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 14)
    }

    // MARK: - Recommended categories card

    private var recommendedCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                Text("Recommended to Block")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text("Select these categories in the picker to block the most distracting apps.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(2)

            HStack(spacing: Theme.spacing) {
                ForEach(recommendedLabels, id: \.self) { label in
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(AppColors.brandBackgroundDark.opacity(0.8))
                        Text(label)
                            .font(AppTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBackgroundDark)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule().fill(AppColors.accent)
                    )
                }
            }
            .padding(.top, 2)
        }
        .padding(Theme.spacing3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.accent.opacity(0.45), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Selection card

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Your selection")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)

            // Count badge
            HStack(spacing: 8) {
                if viewModel.totalSelectedCount > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                    Text("\(viewModel.totalSelectedCount) apps & categories selected")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Image(systemName: "app.badge")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                    Text("No apps selected yet")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if viewModel.totalSelectedCount > 0 {
                    Text("\(viewModel.totalSelectedCount)")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.brandBackgroundDark)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(AppColors.accent))
                }
            }
            .animation(AppMotion.standard, value: viewModel.totalSelectedCount)

            // Open picker button
            Button {
                showBlockedPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Open App Picker")
                        .font(AppTypography.button)
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .fill(AppColors.accent)
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.12), .clear],
                                startPoint: .top, endPoint: .bottom
                            ))
                    }
                    .shadow(color: AppColors.accent.opacity(0.45), radius: 14, x: 0, y: 6)
                )
            }
            .buttonStyle(PressableButtonStyle())

            Text("In the picker, browse by category or search for specific apps.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary.opacity(0.70))
                .lineSpacing(2)
        }
        .padding(Theme.spacing3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(
                            viewModel.totalSelectedCount > 0
                                ? AppColors.accent.opacity(0.40)
                                : AppColors.border.opacity(0.45),
                            lineWidth: 1
                        )
                )
        )
        .animation(AppMotion.standard, value: viewModel.totalSelectedCount > 0)
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Auth error banner

    private func authErrorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.red)
            Text(message)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacing2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Color.red.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(Color.red.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.spacing3)
    }

    // MARK: - Sticky footer

    private var stickyFooter: some View {
        Button {
            guard !isSaving else { return }
            isSaving = true
            Task {
                await viewModel.persistSelections()
                await viewModel.markComplete()
                await viewModel.applyInitialShield()
                await MainActor.run {
                    isSaving = false
                    onFinish()
                }
            }
        } label: {
            Group {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                } else {
                    Text("Continue")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(continueBackground)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(viewModel.totalSelectedCount == 0 || isSaving)
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
        let isEnabled = viewModel.totalSelectedCount > 0 && !isSaving
        return ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(isEnabled ? AppColors.accent : AppColors.accent.opacity(0.30))
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.12), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
        }
        .shadow(color: isEnabled ? AppColors.accent.opacity(0.45) : .clear, radius: 18, x: 0, y: 8)
        .animation(AppMotion.snappy, value: isEnabled)
    }
}
