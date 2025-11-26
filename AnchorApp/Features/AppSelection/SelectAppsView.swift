import SwiftUI
import FamilyControls

struct SelectAppsView: View {
    @StateObject private var viewModel = SelectAppsViewModel()
    @State private var showPicker = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.padding) {
                    // Header Section
                    VStack(spacing: Theme.spacing) {
                        Text("Choose Apps to Block")
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("These apps won't open during your Anchor session.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.padding)
                    }
                    .padding(.top, Theme.padding * 2)
                    .padding(.bottom, Theme.padding)
                    
                    // Selected Apps Card
                    VStack(alignment: .leading, spacing: Theme.spacing) {
                        HStack {
                            Text("Selected Apps")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            if !viewModel.applicationTokens.isEmpty {
                                Text("\(viewModel.applicationTokens.count)")
                                    .font(AppTypography.captionBold)
                                    .foregroundColor(AppColors.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(AppColors.accent.opacity(0.2))
                                            .overlay(
                                                Capsule()
                                                    .stroke(AppColors.accent.opacity(0.4), lineWidth: 1)
                                            )
                                    )
                                    .shadow(color: AppColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        
                        if viewModel.applicationTokens.isEmpty {
                            VStack(spacing: Theme.spacing) {
                                Image(systemName: "app.badge")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                
                                Text("No apps selected")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.padding * 2)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(viewModel.applicationTokens.enumerated()), id: \.offset) { index, token in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppColors.accent, AppColors.accentLight],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 10, height: 10)
                                            .shadow(color: AppColors.accent.opacity(0.5), radius: 3)
                                        
                                        Text("App Token \(index + 1)")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        // Show a truncated identifier from the token
                                        Text(String(describing: token).prefix(8))
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                    .padding(Theme.padding)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(AppColors.secondaryBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                AppColors.accentLight.opacity(0.3),
                                                AppColors.accent.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: AppColors.accent.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, Theme.padding)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.error)
                            Text(errorMessage)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.error)
                        }
                        .padding(Theme.padding)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(Theme.cornerRadius)
                        .padding(.horizontal, Theme.padding)
                    }
                    
                    // Select Apps Button
                    Button(action: {
                        showPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Select Apps")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .shadow(color: AppColors.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, Theme.spacing)
                    
                    Spacer(minLength: Theme.padding)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            FamilyActivityPickerWrapper(selection: $viewModel.selection) {
                // Save selection when done is tapped
                viewModel.saveSelection()
            }
            .onDisappear {
                // Also save on dismiss (handles cancel case)
                viewModel.saveSelection()
            }
        }
    }
}

#Preview {
    SelectAppsView()
        .preferredColorScheme(.dark)
}

