import SwiftUI
import ManagedSettingsUI
import Shared

// MARK: - Shield View
// Refined anchored experience with controlled blue-to-dark transition.

struct ShieldView: View {
    @StateObject private var viewModel = ShieldViewModel()
    @State private var isAnchoredVisual = false
    @State private var anchorOffset: CGFloat = -48
    @State private var anchorScale: CGFloat = 0.92
    @State private var anchorOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 12
    
    let context: ShieldConfigurationContext
    
    init(context: ShieldConfigurationContext) {
        self.context = context
    }
    
    var body: some View {
        ZStack {
            backgroundLayer
            
            VStack(spacing: ShieldTheme.largeSpacing) {
                Spacer(minLength: 12)
                
                Image(systemName: "anchor.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(AppColors.onPrimary)
                    .shadow(color: AppColors.accentFocus.opacity(0.35), radius: 18, x: 0, y: 10)
                    .offset(y: anchorOffset)
                    .scaleEffect(anchorScale)
                    .opacity(anchorOpacity)
                
                VStack(spacing: ShieldTheme.smallSpacing) {
                    Text(viewModel.title)
                        .font(ShieldTypography.largeTitle)
                        .foregroundColor(AppColors.onPrimary)
                    
                    Text(viewModel.subtitle)
                        .font(ShieldTypography.body)
                        .foregroundColor(AppColors.onPrimarySecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
                .padding(.horizontal, ShieldTheme.padding)
                
                if let remaining = viewModel.remainingTimeText {
                    Text("Time remaining \(remaining)")
                        .font(ShieldTypography.caption)
                        .foregroundColor(AppColors.onPrimarySecondary)
                        .opacity(textOpacity)
                }
                
                progressIndicator
                    .opacity(textOpacity)
                
                Spacer()
                
                actionButtons
            }
            .padding(.horizontal, ShieldTheme.padding)
            .padding(.vertical, ShieldTheme.padding * 2)
        }
        .onAppear {
            viewModel.setContext(context)
            viewModel.refresh()
            viewModel.refreshGoalProgress()
            logShieldHit()
            startAnimations()
        }
    }
    
    private var backgroundLayer: some View {
        LinearGradient(
            colors: isAnchoredVisual
                ? [AppColors.primaryAnchored, AppColors.backgroundAnchored]
                : [AppColors.primaryUnlocked, AppColors.accentFocus],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [
                    AppColors.accentFocus.opacity(isAnchoredVisual ? 0.12 : 0.2),
                    Color.clear
                ],
                center: .top,
                startRadius: 40,
                endRadius: 280
            )
        )
        .ignoresSafeArea()
    }
    
    private var progressIndicator: some View {
        VStack(spacing: ShieldTheme.smallSpacing) {
            if viewModel.goalTotalCount > 0 {
                Text(viewModel.goalProgressText ?? "")
                    .font(ShieldTypography.caption)
                    .foregroundColor(AppColors.onPrimarySecondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.onPrimary.opacity(0.18))
                            .frame(height: 5)
                        
                        Capsule()
                            .fill(AppColors.accentFocus)
                            .frame(
                                width: geometry.size.width * CGFloat(viewModel.goalCompletedCount) / CGFloat(max(viewModel.goalTotalCount, 1)),
                                height: 5
                            )
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, ShieldTheme.padding)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: ShieldTheme.spacing) {
            Button(action: {
                viewModel.openUnlockRequest()
            }) {
                Text(viewModel.primaryButtonTitle)
                    .font(ShieldTypography.bodyBold)
                    .foregroundColor(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                            .fill(AppColors.accentFocus)
                    )
            }
            .buttonStyle(ShieldButtonStyle())
            
            Button(action: {
                viewModel.openAnchorApp()
            }) {
                Text(viewModel.secondaryButtonTitle)
                    .font(ShieldTypography.caption)
                    .foregroundColor(AppColors.onPrimarySecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                            .stroke(AppColors.onPrimary.opacity(0.25), lineWidth: 1)
                    )
            }
            .buttonStyle(ShieldButtonStyle())
        }
        .padding(.bottom, ShieldTheme.padding)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2)) {
            isAnchoredVisual = true
        }
        
        withAnimation(.easeOut(duration: 0.7)) {
            anchorOpacity = 1.0
            anchorOffset = 0
            anchorScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
            textOpacity = 1.0
            textOffset = 0
        }
    }

    private func logShieldHit() {
        let lastHit = AppGroupStorage.shared.getLastShieldHitAt()
        let now = Date()
        AppGroupStorage.shared.setLastShieldHit(at: now)
        let userState: AnalyticsUserState = .anchored
        var doubleValues: [String: Double] = [:]
        if let lastHit {
            doubleValues["impulseRecoverySeconds"] = max(now.timeIntervalSince(lastHit), 0)
        }
        let salt = AppGroupStorage.shared.getOrCreateAnalyticsSalt()
        let tokenHash = AnalyticsUtilities.hashToken(viewModel.blockedAppToken, salt: salt)
        let metrics = AnalyticsMetrics(
            doubleValues: doubleValues,
            stringValues: tokenHash.map { ["appTokenHash": $0] } ?? [:]
        )
        let payload = AnalyticsPayload(userState: userState, metrics: metrics)
        AnalyticsServiceProvider.shared.log(event: .shieldHit, payload: payload)
    }
}

// MARK: - Shield Button Style
// Lightweight button style for extension performance
struct ShieldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(ShieldTheme.easeInOut, value: configuration.isPressed)
    }
}
