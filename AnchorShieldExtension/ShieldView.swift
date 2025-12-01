import SwiftUI
import ManagedSettingsUI
import Shared

// MARK: - Shield View
// Full-screen glassmorphism shield with purple tint and glowing logo

struct ShieldView: View {
    @StateObject private var viewModel = ShieldViewModel()
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    @State private var glassOffset: CGFloat = 0
    @State private var logoYOffset: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.0
    let context: ShieldConfigurationContext
    
    private let goalService = GoalService.shared
    
    var body: some View {
        ZStack {
            // Base background with purple tint
            AppColors.anchorPrimaryDark
                .ignoresSafeArea()
            
            // Purple gradient overlay
            LinearGradient(
                colors: [
                    AppColors.anchorPrimary.opacity(0.8),
                    AppColors.anchorAccent.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Glassmorphism panel
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: ShieldTheme.largeSpacing) {
                    // Centered Anchor Logo with glow
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.7, green: 0.5, blue: 1.0).opacity(0.4),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .opacity(logoOpacity)
                        
                        // Logo
                        Image(systemName: "anchor.fill")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppColors.onPrimary,
                                        AppColors.anchorLavender
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(logoScale)
                            .offset(y: logoYOffset)
                    }
                    .padding(.bottom, ShieldTheme.spacing)
                    
                    // Main Message
                    Text("Stay Locked In")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.onPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Secondary text
                    Text("Complete your goals to unlock")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.onPrimarySecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ShieldTheme.padding)
                    
                    // Progress Indicator
                    progressIndicator
                        .padding(.top, ShieldTheme.spacing)
                    
                    Spacer(minLength: 40)
                    
                    // Unlock Options
                    VStack(spacing: ShieldTheme.spacing) {
                        Button(action: {
                            viewModel.openUnlockRequest()
                        }) {
                            Text("Request Unlock")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.onPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                                        .fill(AppColors.onPrimary.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                                                .stroke(AppColors.onPrimary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(ShieldButtonStyle())
                        
                        Button(action: {
                            // Ripple effect
                            withAnimation(.easeOut(duration: 0.4)) {
                                rippleScale = 1.3
                                rippleOpacity = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                rippleScale = 1.0
                                rippleOpacity = 0.0
                            }
                            viewModel.openAnchorApp()
                        }) {
                            ZStack {
                                // Ripple effect
                                Circle()
                                    .fill(AppColors.onPrimary.opacity(rippleOpacity))
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(rippleScale)
                                    .blur(radius: 20)
                                
                                Text("Return to Anchor")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.onPrimarySecondary)
                            }
                        }
                        .buttonStyle(ShieldButtonStyle())
                    }
                    .padding(.horizontal, ShieldTheme.padding)
                    .padding(.bottom, ShieldTheme.padding * 2)
                }
                .padding(.vertical, ShieldTheme.padding * 2)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                // Purple tint overlay
                                LinearGradient(
                                    colors: [
                                        AppColors.anchorPrimary.opacity(0.3),
                                        AppColors.anchorAccent.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Shimmering gradient
                        LinearGradient(
                            colors: [
                                Color.clear,
                                AppColors.onPrimary.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: shimmerOffset)
                        .blur(radius: 20)
                    }
                )
                .offset(y: glassOffset)
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.refresh()
            startAnimations()
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        let goals = goalService.loadGoals()
        let completed = goals.filter { $0.isCompleted }.count
        let total = goals.count
        
        return VStack(spacing: ShieldTheme.smallSpacing) {
                if total > 0 {
                HStack(spacing: ShieldTheme.smallSpacing) {
                    Text("\(completed)/\(total) goals completed")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.onPrimarySecondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.onPrimary.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.onPrimary,
                                        AppColors.anchorLavender
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(completed) / CGFloat(max(total, 1)), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, ShieldTheme.padding)
            } else {
                Text("No goals set")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.onPrimarySecondary)
            }
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Slow pulsing logo
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            logoScale = 1.05
            logoOpacity = 0.8
        }
        
        // Floating logo (up/down 2-3pt)
        withAnimation(
            Animation.easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
        ) {
            logoYOffset = -2.5
        }
        
        // Soft breathing glass panel
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            glassOffset = 2
        }
        
        // Shimmering gradient
        withAnimation(
            Animation.linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 400
        }
    }
}

// MARK: - Shield Button Style
// Lightweight button style for extension performance
struct ShieldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(ShieldTheme.easeInOut, value: configuration.isPressed)
    }
}

