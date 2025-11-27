import SwiftUI

struct ActiveSessionMockView: View {
    @StateObject private var viewModel = ActiveSessionMockViewModel()
    
    var body: some View {
        ZStack {
            // Subtle background gradient
            LinearGradient(
                colors: [
                    AppColors.background,
                    AppColors.secondaryBackground.opacity(0.5),
                    AppColors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: Theme.padding * 2) {
                Spacer()
                
                // Circular progress ring with countdown
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(
                            AppColors.accent.opacity(0.1),
                            lineWidth: 12
                        )
                        .frame(width: 280, height: 280)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accent,
                                    AppColors.accentLight
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 12,
                                lineCap: .round
                            )
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: viewModel.progress)
                        .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 0)
                    
                    // Countdown time
                    VStack(spacing: Theme.spacing) {
                        Text(viewModel.formattedTime)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        
                        Text("Session Active")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }
                }
                .padding(.vertical, Theme.padding * 2)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: Theme.padding) {
                    // End Session button (deep purple)
                    Button(action: {
                        viewModel.endSession()
                    }) {
                        Text("End Session")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .cornerRadius(AppLayout.buttonCornerRadius)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(viewModel.isRunning ? 1.0 : 0.98)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isRunning)
                    
                    // Submit Proof button (outline lavender)
                    Button(action: {
                        viewModel.submitProof()
                    }) {
                        Text("Submit Proof")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .cornerRadius(AppLayout.buttonCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                                    .stroke(AppColors.accentLight, lineWidth: 2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, Theme.padding * 2)
                .padding(.bottom, Theme.padding * 3)
            }
        }
        .navigationTitle("Active Session")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        ActiveSessionMockView()
    }
}

