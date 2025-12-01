import SwiftUI
import Shared

/// New unlock request submission view matching the spec
struct UnlockRequestSubmitView: View {
    let sessionId: UUID?
    @StateObject private var viewModel = UnlockRequestsViewModel()
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedEvidenceType: EvidenceType?
    @State private var message: String = ""
    @State private var showPhotoCapture = false
    @State private var showSuccessView = false
    @State private var capturedPhoto: UIImage?
    
    enum EvidenceType: String, CaseIterable {
        case photo = "Photo Proof"
        case witness = "Witness Confirmation"
        case other = "Other Evidence"
        
        var icon: String {
            switch self {
            case .photo: return "camera.fill"
            case .witness: return "person.2.fill"
            case .other: return "doc.text.fill"
            }
        }
        
        var description: String {
            switch self {
            case .photo: return "Take a photo as proof"
            case .witness: return "Have a friend confirm"
            case .other: return "Provide other evidence"
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if showSuccessView {
                successView
            } else {
                ScrollView {
                    VStack(spacing: Theme.spacing3) {
                        // Title
                        Text("Submit Proof")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.spacing2)
                            .padding(.top, Theme.spacing2)
                        
                        // Habit Summary Card
                        habitSummaryCard
                        
                        // Evidence Options
                        evidenceOptionsSection
                        
                        // Optional Message Input
                        messageInputSection
                        
                        // Submit Button
                        submitButton
                    }
                    .padding(.bottom, Theme.spacing3)
                }
            }
        }
        .navigationTitle("Request Unlock")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPhotoCapture) {
            NavigationStack {
                ProofCaptureView(sessionId: sessionId)
            }
        }
    }
    
    // MARK: - Habit Summary Card
    private var habitSummaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Today's Goals")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            let goals = goalService.loadGoals()
            if goals.isEmpty {
                Text("No goals set")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    ForEach(goals.prefix(3)) { goal in
                        HStack {
                            Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(goal.isCompleted ? AppColors.success : AppColors.textSecondary)
                            Text(goal.name)
                                .font(AppTypography.body)
                                .foregroundColor(goal.isCompleted ? AppColors.textSecondary : AppColors.textPrimary)
                                .strikethrough(goal.isCompleted)
                        }
                    }
                    
                    if goals.count > 3 {
                        Text("+ \(goals.count - 3) more")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.anchorLavender.opacity(0.3),
                            AppColors.anchorAccent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Evidence Options
    private var evidenceOptionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Evidence Options")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            VStack(spacing: Theme.spacing) {
                ForEach(EvidenceType.allCases, id: \.self) { evidenceType in
                    EvidenceOptionButton(
                        evidenceType: evidenceType,
                        isSelected: selectedEvidenceType == evidenceType,
                        onSelect: {
                            withAnimation(Theme.springAnimationFast) {
                                if selectedEvidenceType == evidenceType {
                                    selectedEvidenceType = nil
                                } else {
                                    selectedEvidenceType = evidenceType
                                    if evidenceType == .photo {
                                        showPhotoCapture = true
                                    }
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.spacing2)
        }
    }
    
    // MARK: - Message Input
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Optional Message")
                .font(AppTypography.bodyBold)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            TextField("Add a message (optional)", text: $message, axis: .vertical)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .padding(Theme.spacing2)
                .background(AppColors.secondaryBackground)
                .cornerRadius(Theme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                )
                .lineLimit(3...6)
                .padding(.horizontal, Theme.spacing2)
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            submitRequest()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                        .padding(.trailing, Theme.spacing)
                }
                Text("Submit Request")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(selectedEvidenceType == nil || viewModel.isLoading)
        .padding(.horizontal, Theme.spacing2)
        .padding(.top, Theme.spacing)
    }
    
    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: Theme.spacing3) {
            Spacer()
            
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.success.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.success)
            }
            
            Text("Request Sent")
                .font(AppTypography.largeTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Your friend will approve shortly.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing3)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacing3)
            .padding(.bottom, Theme.spacing3)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    // MARK: - Helper Methods
    private func submitRequest() {
        guard selectedEvidenceType != nil else { return }
        
        HapticFeedback.success()
        
        Task {
            // TODO: Integrate with UnlockRequestService to send request
            // For now, just show success
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                withAnimation(Theme.springAnimation) {
                    showSuccessView = true
                }
            }
        }
    }
}

// MARK: - Evidence Option Button
struct EvidenceOptionButton: View {
    let evidenceType: UnlockRequestSubmitView.EvidenceType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.spacing2) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(
                            isSelected ? AppColors.anchorAccent.opacity(0.2) : AppColors.secondaryBackground
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: evidenceType.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? AppColors.anchorAccent : AppColors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                    Text(evidenceType.rawValue)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(evidenceType.description)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                }
            }
            .padding(Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(isSelected ? AppColors.anchorLavender.opacity(0.1) : AppColors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(
                        isSelected ? AppColors.anchorAccent : AppColors.textSecondary.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

