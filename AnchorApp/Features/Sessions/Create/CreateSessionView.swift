import SwiftUI

struct CreateSessionView: View {
    @StateObject private var viewModel = CreateSessionViewModel()
    @State private var gradientOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Animated gradient header
                    gradientHeader
                        .padding(.top, 20)
                    
                    // Duration picker card
                    durationPickerCard
                    
                    // Friend selection card
                    friendSelectionCard
                    
                    // Start session button
                    startSessionButton
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            startGradientAnimation()
        }
    }
    
    // MARK: - Gradient Header
    private var gradientHeader: some View {
        VStack(spacing: 12) {
            Text("Start Focus Session")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text("Lock in your focus with accountability")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.accentLight
                ]),
                startPoint: UnitPoint(x: 0 - gradientOffset, y: 0),
                endPoint: UnitPoint(x: 1 - gradientOffset, y: 1)
            )
        )
        .cornerRadius(AppLayout.cardCornerRadius)
        .shadow(color: AppColors.accent.opacity(0.3), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.accentLight.opacity(0.6),
                            AppColors.accent.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Duration Picker Card
    private var durationPickerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.system(size: 20, weight: .semibold))
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
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppLayout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(AppColors.accentLight.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func durationButton(duration: Int) -> some View {
        Button(action: {
            viewModel.selectedDuration = duration
        }) {
            VStack(spacing: 4) {
                Text("\(duration)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(
                        viewModel.selectedDuration == duration
                            ? AppColors.textPrimary
                            : AppColors.textSecondary
                    )
                
                Text("min")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(
                        viewModel.selectedDuration == duration
                            ? AppColors.accentLight
                            : AppColors.textSecondary.opacity(0.6)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.selectedDuration == duration
                    ? AppColors.accent.opacity(0.2)
                    : Color.clear
            )
            .cornerRadius(AppLayout.chipCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                    .stroke(
                        viewModel.selectedDuration == duration
                            ? AppColors.accentLight
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Friend Selection Card
    private var friendSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Friends")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(viewModel.mockFriends) { friend in
                    friendRow(friend: friend)
                }
            }
        }
        .padding(20)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppLayout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(AppColors.accentLight.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func friendRow(friend: MockFriend) -> some View {
        Button(action: {
            viewModel.toggleFriend(friend.id)
        }) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            viewModel.selectedFriends.contains(friend.id)
                                ? AppColors.accent
                                : Color.clear
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    viewModel.selectedFriends.contains(friend.id)
                                        ? AppColors.accentLight
                                        : AppColors.textSecondary.opacity(0.4),
                                    lineWidth: 2
                                )
                        )
                    
                    if viewModel.selectedFriends.contains(friend.id) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                // Friend name
                Text(friend.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Start Session Button
    private var startSessionButton: some View {
        Button(action: {
            viewModel.startSession()
        }) {
            HStack {
                Spacer()
                Text("Start Session")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.accent,
                        AppColors.accentLight
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppLayout.buttonCornerRadius)
            .shadow(color: AppColors.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                    .stroke(AppColors.accentLight.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Animation
    private func startGradientAnimation() {
        withAnimation(
            Animation.linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            gradientOffset = 1.0
        }
    }
}

#Preview {
    CreateSessionView()
}

