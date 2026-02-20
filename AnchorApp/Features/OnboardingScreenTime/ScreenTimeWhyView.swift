import SwiftUI

struct ScreenTimeWhyView: View {
    let onContinue: () -> Void
    
    private let reasons = [
        ReasonItem(
            icon: "app.badge.checkmark",
            title: "Identify Distracting Apps",
            description: "Anchor needs Screen Time access to see which apps you use most"
        ),
        ReasonItem(
            icon: "lock.shield.fill",
            title: "Block During Sessions",
            description: "We'll block distracting apps when you start a Anchored Mode"
        ),
        ReasonItem(
            icon: "person.2.fill",
            title: "Unlock control",
            description: "Apps unlock when you complete your goals."
        )
    ]
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing4) {
                    // Header
                    VStack(spacing: Theme.spacing2) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                                .fill(AppColors.secondaryBackground)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "lock.shield.fill")
                                .font(AppTypography.screenTitle).fontWeight(.light)
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.top, Theme.spacing3)
                        
                        Text("Why We Need Screen Time Access")
                            .font(AppTypography.screenTitle)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Anchor uses Screen Time to help you stay focused and accountable")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing3)
                    }
                    .padding(.bottom, Theme.spacing2)
                    
                    // Reasons list
                    VStack(spacing: Theme.spacing2) {
                        ForEach(reasons, id: \.title) { reason in
                            ReasonRowView(reason: reason)
                        }
                    }
                    .padding(.horizontal, Theme.spacing3)
                    
                    Spacer(minLength: Theme.spacing4)
                    
                    Button(action: onContinue) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Theme.spacing3)
                    .padding(.bottom, Theme.spacing3)
                }
            }
        }
    }
}

struct ReasonItem {
    let icon: String
    let title: String
    let description: String
}

struct ReasonRowView: View {
    let reason: ReasonItem
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacing2) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: reason.icon)
                    .font(AppTypography.body).fontWeight(.medium)
                    .foregroundColor(AppColors.accent)
            }
            
            VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                Text(reason.title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(reason.description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

