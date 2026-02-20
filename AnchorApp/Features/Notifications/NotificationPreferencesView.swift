import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @State private var animatedSections: Set<String> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                sessionRemindersSection
                dailyReportsSection
                saveButton
            }
            .padding(.horizontal, Theme.padding)
            .padding(.vertical, 20)
        }
        .background(AppColors.background)
        .navigationTitle("Notification Preferences")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Notification Preferences")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)

            Text("Customize how and when you receive notifications")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Session Reminders

    private var sessionRemindersSection: some View {
        sectionCard(title: "Session Reminders", sectionKey: "session", icon: "clock.fill") {
            VStack(spacing: 16) {
                toggleCard(title: "5 minutes left reminder", isOn: $viewModel.notify5MinReminder)
                toggleCard(title: "End of session alert", isOn: $viewModel.notifyEndOfSession)
            }
        }
        .onAppear { animate(sectionKey: "session", delay: 0.2) }
    }

    // MARK: - Daily Reports

    private var dailyReportsSection: some View {
        sectionCard(title: "Daily Reports", sectionKey: "reports", icon: "chart.bar.fill") {
            VStack(spacing: 16) {
                toggleCard(title: "Daily Accountability Summary", isOn: $viewModel.notifyDailySummary)
                toggleCard(title: "Weekly Summary", isOn: $viewModel.notifyWeeklySummary)
            }
        }
        .onAppear { animate(sectionKey: "reports", delay: 0.3) }
    }

    private func animate(sectionKey: String, delay: Double) {
        if reduceMotion {
            _ = animatedSections.insert(sectionKey)
        } else {
            withAnimation(AppMotion.gentleSpring.delay(delay)) {
                _ = animatedSections.insert(sectionKey)
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        title: String,
        sectionKey: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(AppTypography.body).fontWeight(.semibold)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.horizontal, 4)
            .opacity(animatedSections.contains(sectionKey) ? 1 : 0)
            .offset(x: animatedSections.contains(sectionKey) ? 0 : -20)

            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(AppColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accent.opacity(0.3),
                                    AppColors.textTertiary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: AppColors.accent.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Toggle Row

    private func toggleCard(title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            AnchorToggle(isOn: isOn)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                .fill(AppColors.background.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accent.opacity(0.2),
                                    AppColors.textTertiary.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: AppColors.accent.opacity(0.15), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            viewModel.savePreferences()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(AppTypography.body).fontWeight(.semibold)

                Text("Save Preferences")
                    .font(AppTypography.body)
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent, AppColors.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppColors.accent.opacity(0.4), radius: 12, x: 0, y: 4)
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - AnchorToggle (renamed to avoid redeclaration collisions)

struct AnchorToggle: View {
    @Binding var isOn: Bool
    @State private var isAnimating: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                .fill(trackColor)
                .frame(width: 50, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                        .stroke(isOn ? AppColors.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: isOn ? AppColors.accent.opacity(0.3) : Color.clear, radius: 6)

            Circle()
                .fill(
                    LinearGradient(
                        colors: isOn
                            ? [AppColors.accent, AppColors.textTertiary]
                            : [AppColors.textSecondary.opacity(0.5), AppColors.textSecondary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)
                .padding(3)
                .shadow(color: thumbGlowColor, radius: isOn ? 10 : 0)
                .shadow(color: thumbGlowColor.opacity(0.5), radius: isOn ? 6 : 0)
                .scaleEffect(isAnimating ? 1.12 : 1.0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if reduceMotion {
                isOn.toggle()
                isAnimating = false
            } else {
                withAnimation(AppMotion.gentleSpring) {
                    isOn.toggle()
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(AppMotion.gentleSpring) {
                        isAnimating = false
                    }
                }
            }
        }
    }

    private var trackColor: Color {
        isOn ? AppColors.textTertiary.opacity(0.25) : AppColors.secondaryBackground.opacity(0.6)
    }

    private var thumbGlowColor: Color {
        isOn ? AppColors.accent.opacity(0.8) : Color.clear
    }
}

#Preview {
    NavigationView {
        NotificationPreferencesView()
    }
    .preferredColorScheme(.dark)
}
