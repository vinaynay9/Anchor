import SwiftUI
import Shared

// MARK: - Lock Schedule View
// Onboarding step 3: pick the nightly lock time.
// Default is midnight (12:00 AM). Range: 8 PM → 4 AM.

struct LockScheduleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var viewModel: LockScheduleViewModel
    @State private var showContent = false
    // Tiny drift for the clock icon
    @State private var clockPulse = false

    let onNext: () -> Void

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
                    Spacer().frame(height: Theme.spacing5)
                    clockIllustration
                    Spacer().frame(height: Theme.spacing4)
                    timePicker
                    Spacer().frame(height: Theme.spacing3)
                    explanationCard
                    Spacer().frame(height: 120)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            stickyFooter
        }
        .ignoresSafeArea()
        .onAppear {
            guard !showContent else { return }
            if reduceMotion {
                showContent = true
            } else {
                withAnimation(AppMotion.gentleSpring.delay(0.06)) { showContent = true }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.5)) {
                    clockPulse = true
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Lock Schedule")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("What time should your apps lock each night?")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing4)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 14)
    }

    // MARK: - Clock illustration

    private var clockIllustration: some View {
        ZStack {
            // Glow ring
            Circle()
                .stroke(AppColors.accent.opacity(0.20), lineWidth: 1)
                .frame(width: 110, height: 110)
                .scaleEffect(clockPulse ? 1.06 : 1.0)

            // Glass disc
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle().fill(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.16), AppColors.primary.opacity(0.07)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(Circle().stroke(AppColors.accent.opacity(0.28), lineWidth: 1))
                .frame(width: 82, height: 82)
                .shadow(color: AppColors.accent.opacity(0.25), radius: 22, x: 0, y: 8)

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.textPrimary, AppColors.accent.opacity(0.80)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .scaleEffect(clockPulse ? 1.04 : 1.0)
        }
        .frame(height: 120)
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.85)
    }

    // MARK: - Time picker (wheel style)

    private var timePicker: some View {
        VStack(spacing: Theme.spacing2) {
            Text("Lock time")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.spacing3)

            // Wheel-style picker over the allowed rows
            Picker("Lock time", selection: Binding(
                get: { viewModel.selectedRow },
                set: { viewModel.select(row: $0) }
            )) {
                ForEach(LockScheduleViewModel.allowedRows) { row in
                    Text(row.displayLabel)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .tag(row)
                }
            }
            .pickerStyle(.wheel)
            .colorScheme(.dark)
            .frame(height: 160)
            .clipped()
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(AppColors.border.opacity(0.45), lineWidth: 1)
                    )
            )
            .padding(.horizontal, Theme.spacing3)
        }
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Explanation card

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: viewModel.isEveningLock ? "moon.fill" : "moon.stars.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.accent.opacity(0.85))

                Text(viewModel.explanationText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.spacing2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.accent.opacity(0.28), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
        .animation(AppMotion.standard, value: viewModel.explanationText)
    }

    // MARK: - Sticky footer

    private var stickyFooter: some View {
        Button {
            viewModel.save()
            onNext()
        } label: {
            Text("Continue")
                .font(AppTypography.button)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(continueBackground)
        }
        .buttonStyle(PressableButtonStyle())
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
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium).fill(AppColors.accent)
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.12), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
        }
        .shadow(color: AppColors.accent.opacity(0.45), radius: 18, x: 0, y: 8)
    }
}

// MARK: - Preview

#Preview {
    LockScheduleView(viewModel: LockScheduleViewModel(), onNext: {})
}
