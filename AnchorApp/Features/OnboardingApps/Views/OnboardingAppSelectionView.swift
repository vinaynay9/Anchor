import SwiftUI
import FamilyControls

struct OnboardingAppSelectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var viewModel: OnboardingAppSelectionViewModel
    @State private var showBlockedPicker = false
    @State private var showUnlockedPicker = false
    @State private var isSaving = false

    let onFinish: () -> Void

    private let presets = [
        "Socials",
        "Games",
        "Sports (Fantasy / Betting / Stats)",
        "Video",
        "Shopping",
        "Food",
        "Browsers"
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    header

                    presetsSection

                    selectionSection(
                        title: "Apps to block",
                        description: "Select apps you want blocked during Anchored Mode.",
                        buttonTitle: "Select apps",
                        selection: $viewModel.blockedSelection,
                        showPicker: $showBlockedPicker
                    )

                    if viewModel.showUnlockedAppsSection {
                        selectionSection(
                            title: "Apps you can earn",
                            description: "Select apps you can unlock by completing goals.",
                            buttonTitle: "Select apps",
                            selection: $viewModel.unlockedSelection,
                            showPicker: $showUnlockedPicker
                        )
                    }
                }
                .padding(.vertical, Theme.spacing4)
                .padding(.bottom, Theme.spacing5)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.spacing) {
                Button(action: finish) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                    } else {
                        Text("Finish")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryPressableButtonStyle())
                .disabled(!viewModel.hasBlockedSelection || isSaving)
                .accessibilityLabel(viewModel.hasBlockedSelection ? "Finish onboarding" : "Select apps to continue")
            }
            .padding(.horizontal, Theme.spacing3)
            .padding(.vertical, Theme.spacing2)
            .background(AppColors.background.opacity(0.95))
        }
        .sheet(isPresented: $showBlockedPicker) {
            FamilyActivityPickerWrapper(selection: $viewModel.blockedSelection)
        }
        .sheet(isPresented: $showUnlockedPicker) {
            FamilyActivityPickerWrapper(selection: $viewModel.unlockedSelection)
        }
        .task {
            await viewModel.loadState()
        }
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: viewModel.showUnlockedAppsSection)
    }

    private var header: some View {
        VStack(spacing: Theme.spacing2) {
            Text("Select apps to block")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.onboardingTitleText)
                .multilineTextAlignment(.center)

            Text("Presets are suggestions. You can edit anytime.")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.onboardingBodyText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.spacing3)
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Suggested presets")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.onboardingTitleText)
                .padding(.horizontal, Theme.spacing3)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: Theme.spacing2)], spacing: Theme.spacing2) {
                ForEach(presets, id: \.self) { preset in
                    Button(action: { togglePreset(preset) }) {
                        Text(preset)
                            .font(AppTypography.helper)
                            .foregroundColor(viewModel.selectedPresets.contains(preset) ? AppColors.onPrimary : AppColors.onboardingBodyText)
                            .padding(.vertical, Theme.spacing)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedPresets.contains(preset) ? AppColors.accent : AppColors.surface)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, Theme.spacing3)

            Text("Sports includes fantasy, betting, and stats (Kalshi, Polymarket). Presets don’t auto-select apps on iOS.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.onboardingHintText)
                .padding(.horizontal, Theme.spacing3)
        }
    }

    private func selectionSection(
        title: String,
        description: String,
        buttonTitle: String,
        selection: Binding<FamilyActivitySelection>,
        showPicker: Binding<Bool>
    ) -> some View {
        let selectionCount = selection.wrappedValue.applicationTokens.count + selection.wrappedValue.categoryTokens.count

        return VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text(title)
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.onboardingTitleText)

            HStack {
                Text(description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                Spacer()
                Text(selectionCount == 0 ? "None" : "\(selectionCount) selected")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.onboardingHintText)
            }

            Button(action: { showPicker.wrappedValue = true }) {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryPressableButtonStyle())
        }
        .padding(Theme.spacing3)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(selectionCount > 0 ? AppColors.accent.opacity(0.5) : AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
        .padding(.horizontal, Theme.spacing3)
    }

    private func togglePreset(_ preset: String) {
        if viewModel.selectedPresets.contains(preset) {
            viewModel.selectedPresets.remove(preset)
        } else {
            viewModel.selectedPresets.insert(preset)
        }
    }

    private func finish() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            await viewModel.persistSelections()
            await viewModel.markComplete()
            await MainActor.run {
                isSaving = false
                onFinish()
            }
        }
    }
}
