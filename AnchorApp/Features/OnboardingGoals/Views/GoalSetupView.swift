import SwiftUI
import Shared

// MARK: - Goal Setup View
// Onboarding step: create at least 3 goals before continuing.
// Each goal has a name, category picker, and optional collapsible notes field.

struct GoalSetupView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var viewModel: GoalSetupViewModel
    @State private var showContent = false

    let onNext: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Background ───────────────────────────────────────────────
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── Scrollable content ───────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)
                    header
                    Spacer().frame(height: Theme.spacing4)
                    tipBanner
                    Spacer().frame(height: Theme.spacing3)
                    goalList
                    addGoalButton
                    Spacer().frame(height: 120) // room for the sticky footer
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // ── Sticky footer ────────────────────────────────────────────
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
            Text("Set Your Goals")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("What will you do before unlocking your apps each day?")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing4)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 14)
        .padding(.horizontal, Theme.spacing3)
    }

    // MARK: - Tip banner

    private var tipBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.warning)

            Text("**Tip:** Add notes to your goals to track specific targets, like \"Complete 2 Duolingo lessons\" or \"Run 3 miles\".")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
        }
        .padding(Theme.spacing2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.warning.opacity(0.30), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Goal list

    private var goalList: some View {
        LazyVStack(spacing: Theme.spacing2) {
            ForEach(viewModel.drafts) { draft in
                GoalDraftCard(
                    draft: binding(for: draft.id),
                    onDelete: {
                        withAnimation(AppMotion.standard) {
                            viewModel.remove(id: draft.id)
                        }
                    },
                    onToggleNotes: { viewModel.toggleNotes(id: draft.id) }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal:   .opacity.combined(with: .scale(scale: 0.92))
                ))
            }
        }
        .padding(.horizontal, Theme.spacing3)
        .animation(AppMotion.standard, value: viewModel.drafts.count)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Add Goal button

    private var addGoalButton: some View {
        Button {
            withAnimation(AppMotion.standard) { viewModel.addGoal() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Add Goal")
                    .font(AppTypography.button)
            }
            .foregroundColor(viewModel.canAddMore ? AppColors.accent : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(AppColors.accent.opacity(viewModel.canAddMore ? 0.40 : 0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!viewModel.canAddMore)
        .padding(.horizontal, Theme.spacing3)
        .padding(.top, Theme.spacing2)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Sticky footer (counter + Continue)

    private var stickyFooter: some View {
        VStack(spacing: Theme.spacing) {
            // Minimum counter
            HStack(spacing: 6) {
                Image(systemName: viewModel.counterMet ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.counterMet ? AppColors.success : AppColors.textTertiary)
                Text(viewModel.counterText)
                    .font(AppTypography.caption)
                    .foregroundColor(viewModel.counterMet ? AppColors.success : AppColors.textTertiary)
            }
            .animation(AppMotion.snappy, value: viewModel.counterMet)

            // Continue
            Button(action: onNext) {
                Text("Continue")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(continueBackground)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!viewModel.canContinue)
        }
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
                .fill(viewModel.canContinue ? AppColors.accent : AppColors.accent.opacity(0.30))
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.12), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
        }
        .shadow(
            color: viewModel.canContinue ? AppColors.accent.opacity(0.40) : .clear,
            radius: 18, x: 0, y: 8
        )
        .animation(AppMotion.snappy, value: viewModel.canContinue)
    }

    // MARK: - Helper

    private func binding(for id: UUID) -> Binding<GoalSetupViewModel.GoalDraft> {
        Binding(
            get: { viewModel.drafts.first(where: { $0.id == id }) ?? GoalSetupViewModel.GoalDraft() },
            set: { newVal in
                guard let idx = viewModel.drafts.firstIndex(where: { $0.id == id }) else { return }
                viewModel.drafts[idx] = newVal
            }
        )
    }
}

// MARK: - Goal Draft Card

private struct GoalDraftCard: View {
    @Binding var draft: GoalSetupViewModel.GoalDraft
    let onDelete: () -> Void
    let onToggleNotes: () -> Void

    @FocusState private var titleFocused: Bool

    // Category colour tint
    private var categoryColor: Color {
        switch draft.category {
        case .fitness:       return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .health:        return Color(red: 0.30, green: 0.85, blue: 0.75)
        case .mentalHealth:  return Color(red: 0.60, green: 0.45, blue: 0.95)
        case .learning, .skillDevelopment, .school: return Color(red: 0.40, green: 0.65, blue: 1.00)
        case .work, .career: return Color(red: 1.00, green: 0.70, blue: 0.25)
        case .finance:       return Color(red: 0.40, green: 0.85, blue: 0.55)
        case .relationships: return Color(red: 1.00, green: 0.45, blue: 0.60)
        case .creativity:    return Color(red: 0.90, green: 0.50, blue: 0.95)
        case .home:          return Color(red: 0.85, green: 0.65, blue: 0.40)
        case .other:         return AppColors.textTertiary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            // ── Row 1: title + delete ────────────────────────────────────
            HStack(spacing: Theme.spacing) {
                TextField("Goal name, e.g. \"Go to gym\"", text: $draft.title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .focused($titleFocused)
                    .submitLabel(.done)

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textTertiary.opacity(0.6))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Delete goal")
            }

            // ── Row 2: category chip + notes toggle ──────────────────────
            HStack(spacing: Theme.spacing) {
                // Category picker
                Menu {
                    ForEach(GoalCategory.allCases, id: \.self) { cat in
                        Button(cat.displayName) { draft.category = cat }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: 7, height: 7)
                        Text(draft.category.displayName)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(categoryColor.opacity(0.15))
                            .overlay(Capsule().stroke(categoryColor.opacity(0.35), lineWidth: 0.75))
                    )
                }
                .buttonStyle(PressableButtonStyle())

                Spacer()

                // Notes toggle
                Button(action: onToggleNotes) {
                    HStack(spacing: 4) {
                        Image(systemName: draft.isNotesExpanded ? "note.text" : "note.text.badge.plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text(draft.isNotesExpanded ? "Notes" : "Add notes")
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(draft.isNotesExpanded ? AppColors.accent : AppColors.textTertiary)
                }
                .buttonStyle(PressableButtonStyle())
            }

            // ── Row 3: notes field (collapsible) ─────────────────────────
            if draft.isNotesExpanded {
                TextField(
                    "e.g. \"Complete 2 Duolingo lessons\" or \"Run 3 miles\"",
                    text: $draft.notes,
                    axis: .vertical
                )
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3, reservesSpace: false)
                .padding(Theme.spacing)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                        .fill(AppColors.accent.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                .stroke(AppColors.accent.opacity(0.22), lineWidth: 0.75)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.spacing2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(
                            draft.title.isEmpty
                                ? AppColors.border.opacity(0.45)
                                : AppColors.accent.opacity(0.50),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: draft.title.isEmpty ? .clear : AppColors.accent.opacity(0.12),
            radius: 10, x: 0, y: 4
        )
        .animation(AppMotion.standard, value: draft.isNotesExpanded)
        .animation(AppMotion.snappy, value: draft.title.isEmpty)
        .onTapGesture { titleFocused = true }
    }
}

// MARK: - Preview

#Preview {
    GoalSetupView(viewModel: GoalSetupViewModel(), onNext: {})
}
