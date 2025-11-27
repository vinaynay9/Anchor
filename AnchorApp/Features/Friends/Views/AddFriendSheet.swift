import SwiftUI

struct AddFriendSheet: View {
    @ObservedObject var viewModel: FriendsViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: Theme.padding * 2) {
                    Spacer()
                    
                    // Success Checkmark Animation
                    if viewModel.showAddSuccess {
                        successAnimation
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Input Section
                        inputSection
                            .transition(.opacity)
                    }
                    
                    Spacer()
                }
                .padding(Theme.padding * 2)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        withAnimation {
                            viewModel.isShowingAddSheet = false
                            viewModel.addFriendText = ""
                            viewModel.addError = nil
                        }
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: Theme.padding * 2) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.3),
                                AppColors.accent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.accent)
            }
            .padding(.bottom, Theme.spacing)
            
            // Text Field
            VStack(alignment: .leading, spacing: Theme.spacing) {
                Text("Friend ID or username")
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Enter friend ID or username", text: $viewModel.addFriendText)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(Theme.padding)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppLayout.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                            .stroke(
                                viewModel.addError != nil ? AppColors.error : AppColors.accent.opacity(0.3),
                                lineWidth: viewModel.addError != nil ? 2 : 1
                            )
                    )
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        viewModel.addFriend()
                    }
                
                if let error = viewModel.addError {
                    HStack(spacing: Theme.spacing / 2) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                        
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Add Friend Button
            Button(action: {
                viewModel.addFriend()
            }) {
                HStack {
                    if viewModel.showAddSuccess {
                        Image(systemName: "checkmark")
                            .font(AppTypography.bodyBold)
                    } else {
                        Text("Add Friend")
                            .font(AppTypography.bodyBold)
                    }
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(Theme.padding)
                .background(
                    LinearGradient(
                        colors: [
                            AppColors.primary,
                            AppColors.accent
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppLayout.buttonCornerRadius)
            }
            .disabled(viewModel.showAddSuccess)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var successAnimation: some View {
        VStack(spacing: Theme.padding * 2) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.success.opacity(0.2),
                                AppColors.success.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.success)
            }
            .scaleEffect(viewModel.showAddSuccess ? 1.0 : 0.5)
            .opacity(viewModel.showAddSuccess ? 1.0 : 0.0)
            
            Text("Friend Added!")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

