import SwiftUI
import Shared

// MARK: - Session Home View
// Hero: HH:MM:SS locked timer. Info cards: shield hits + session duration.
// Streak banner at bottom.

struct SessionHomeView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @StateObject private var viewModel = SessionViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)

                    // Error banner
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage) { viewModel.errorMessage = nil }
                            .padding(.horizontal, Theme.spacing3)
                            .padding(.bottom, Theme.spacing3)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    heroSection
                    Spacer().frame(height: Theme.spacing5)
                    infoCardsRow
                    Spacer().frame(height: 120)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            streakBanner
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !showContent else { return }
            if reduceMotion {
                showContent = true
            } else {
                withAnimation(AppMotion.gentleSpring.delay(0.08)) { showContent = true }
            }
        }
        .task { await viewModel.loadDashboardData() }
        .onDisappear { viewModel.stopElapsedTimer() }
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: viewModel.isAnchored)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            if viewModel.isAnchored {
                // Locked timer
                Text(viewModel.lockedTimeDisplay)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: viewModel.lockedElapsedSeconds)

                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                    Text("Locked Today")
                        .font(AppTypography.helper)
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                // Not locked state
                Text("Not Locked")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Start a session to block distracting apps.")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing4)
                    .padding(.top, 4)

                Button {
                    HapticFeedback.selectionChanged()
                    coordinator.navigateToSessionSetup()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Start Session")
                            .font(AppTypography.button)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 50)
                    .padding(.horizontal, Theme.spacing4)
                    .background(
                        ZStack {
                            Capsule().fill(AppColors.accent)
                            Capsule().fill(LinearGradient(
                                colors: [Color.white.opacity(0.14), .clear],
                                startPoint: .top, endPoint: .bottom
                            ))
                        }
                        .shadow(color: AppColors.accent.opacity(0.50), radius: 16, x: 0, y: 6)
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, Theme.spacing2)
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 18)
    }

    // MARK: - Info cards row

    private var infoCardsRow: some View {
        HStack(spacing: Theme.spacing2) {
            infoCard(
                icon: "shield.slash.fill",
                value: "\(viewModel.shieldHitCountToday)",
                label: "Shield Hits Today",
                iconColor: .orange
            )
            infoCard(
                icon: "timer",
                value: viewModel.isAnchored ? viewModel.lockedTimeDisplay : "--:--:--",
                label: "Session Duration",
                iconColor: AppColors.accent
            )
        }
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
    }

    private func infoCard(icon: String, value: String, label: String, iconColor: Color) -> some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing3)
        .padding(.horizontal, Theme.spacing2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.border.opacity(0.40), lineWidth: 1)
                )
        )
    }

    // MARK: - Streak banner

    private var streakBanner: some View {
        HStack(spacing: 8) {
            Text("🔥")
                .font(.system(size: 18))
            Text("Day 1 — Keep going!")
                .font(AppTypography.helper)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, Theme.spacing3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.accent.opacity(0.30), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.spacing3)
        .padding(.bottom, 28)
        .opacity(showContent ? 1 : 0)
    }
}
