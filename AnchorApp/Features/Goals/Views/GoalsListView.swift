import SwiftUI
import Shared

// MARK: - Goals List View
// Shows daily goal cards with completion flow, progress bar, swipe-to-delete, and add sheet.

struct GoalsListView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var selectedGoal: Shared.Goal?
    @State private var goalToDelete: Shared.Goal?
    @State private var showDeleteAlert = false
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)
                    progressHeader
                    Spacer().frame(height: Theme.spacing3)
                    goalsList
                    Spacer().frame(height: 100)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Floating "+" button
            addButton
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        // Goal completion sheet
        .sheet(item: $selectedGoal) { goal in
            GoalCompletionDetailView(goal: goal) {
                Task {
                    withAnimation(AppMotion.standard) {
                        _ = viewModel.isGoalCompleted(goal)
                    }
                    await viewModel.complete(goal: goal)
                }
            }
        }
        // Add goal sheet
        .sheet(isPresented: $viewModel.showAddGoalSheet) {
            AddGoalSheet(viewModel: viewModel)
        }
        // Delete confirmation
        .alert("Remove Goal", isPresented: $showDeleteAlert) {
            Button("Remove", role: .destructive) {
                if let goal = goalToDelete {
                    Task { await viewModel.delete(goal: goal) }
                }
                goalToDelete = nil
            }
            Button("Cancel", role: .cancel) { goalToDelete = nil }
        } message: {
            Text("You have 3 or fewer goals. Removing one will leave you with less than the recommended minimum. Are you sure?")
        }
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .appGroupDidUpdate)) { _ in
            Task { await viewModel.load() }
        }
        .onAppear {
            guard !showContent else { return }
            if reduceMotion {
                showContent = true
            } else {
                withAnimation(AppMotion.gentleSpring.delay(0.06)) { showContent = true }
            }
        }
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            HStack {
                Text("Today's Goals")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(viewModel.progressText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            ProgressView(value: Double(viewModel.completedCount), total: Double(max(viewModel.totalCount, 1)))
                .tint(AppColors.accent)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
                .animation(AppMotion.standard, value: viewModel.completedCount)
        }
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
    }

    // MARK: - Goals list

    private var goalsList: some View {
        VStack(spacing: Theme.spacing2) {
            ForEach(viewModel.goals) { goal in
                GoalCard(
                    goal: goal,
                    isCompleted: viewModel.isGoalCompleted(goal)
                )
                .onTapGesture {
                    if !viewModel.isGoalCompleted(goal) {
                        selectedGoal = goal
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        requestDelete(goal: goal)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .scale(scale: 0.92))
                ))
            }
        }
        .animation(AppMotion.standard, value: viewModel.goals.map(\.id))
        .padding(.horizontal, Theme.spacing3)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Floating add button

    private var addButton: some View {
        Button {
            viewModel.showAddGoalSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 58, height: 58)
                .background(
                    ZStack {
                        Circle().fill(AppColors.accent)
                        Circle().fill(LinearGradient(
                            colors: [Color.white.opacity(0.14), .clear],
                            startPoint: .top, endPoint: .bottom
                        ))
                    }
                    .shadow(color: AppColors.accent.opacity(0.55), radius: 18, x: 0, y: 8)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.trailing, Theme.spacing3)
        .padding(.bottom, 36)
    }

    // MARK: - Delete logic

    private func requestDelete(goal: Shared.Goal) {
        goalToDelete = goal
        if viewModel.goals.count <= 3 {
            showDeleteAlert = true
        } else {
            Task { await viewModel.delete(goal: goal) }
        }
    }
}

// MARK: - Goal Card

private struct GoalCard: View {
    let goal: Shared.Goal
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: Theme.spacing2) {
            // Completion icon
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.20) : AppColors.surface.opacity(0.50))
                    .frame(width: 36, height: 36)
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isCompleted ? .green : AppColors.textSecondary.opacity(0.50))
            }
            .animation(AppMotion.snappy, value: isCompleted)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isCompleted ? AppColors.textSecondary : AppColors.textPrimary)
                    .strikethrough(isCompleted, color: AppColors.textSecondary.opacity(0.5))

                CategoryPill(category: goal.category)
            }

            Spacer()

            if !isCompleted {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary.opacity(0.40))
            }
        }
        .padding(Theme.spacing2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(isCompleted ? Color.green.opacity(0.07) : AppColors.surface.opacity(0.60))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(
                            isCompleted ? Color.green.opacity(0.25) : AppColors.border.opacity(0.35),
                            lineWidth: 1
                        )
                )
        )
        .animation(AppMotion.standard, value: isCompleted)
    }
}

// MARK: - Add Goal Sheet

private struct AddGoalSheet: View {
    @ObservedObject var viewModel: GoalsViewModel
    @FocusState private var titleFocused: Bool

    var body: some View {
        ZStack {
            AppColors.brandBackgroundDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(AppColors.border.opacity(0.45))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, Theme.spacing3)

                Text("Add Goal")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.bottom, Theme.spacing3)

                VStack(spacing: Theme.spacing2) {
                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Goal name")
                            .font(AppTypography.sectionHeader)
                            .foregroundColor(AppColors.textPrimary)

                        TextField("e.g. 30-minute run", text: $viewModel.newGoalTitle)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .focused($titleFocused)
                            .padding(.vertical, 12)
                            .padding(.horizontal, Theme.spacing2)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                            .stroke(
                                                titleFocused ? AppColors.accent.opacity(0.55) : AppColors.border.opacity(0.40),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }

                    // Category picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category")
                            .font(AppTypography.sectionHeader)
                            .foregroundColor(AppColors.textPrimary)

                        Picker("Category", selection: $viewModel.newGoalCategory) {
                            ForEach(GoalCategory.allCases, id: \.self) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.accent)
                        .padding(.vertical, 10)
                        .padding(.horizontal, Theme.spacing2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                        .stroke(AppColors.border.opacity(0.40), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, Theme.spacing3)

                Spacer().frame(height: Theme.spacing4)

                Button {
                    titleFocused = false
                    Task { await viewModel.addGoalFromSheet() }
                } label: {
                    Text("Add Goal")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                    .fill(viewModel.newGoalTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                          ? AppColors.accent.opacity(0.30)
                                          : AppColors.accent)
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                    .fill(LinearGradient(
                                        colors: [Color.white.opacity(0.12), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    ))
                            }
                            .shadow(
                                color: viewModel.newGoalTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? .clear : AppColors.accent.opacity(0.45),
                                radius: 16, x: 0, y: 6
                            )
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(viewModel.newGoalTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, Theme.spacing3)
                .padding(.bottom, 36)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(AppColors.brandBackgroundDark)
        .onAppear { titleFocused = true }
    }
}
