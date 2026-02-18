import SwiftUI
import Shared

struct SessionTimelineView: View {
    let events: [SessionEvent]
    
    @State private var animatedEventIds: Set<UUID> = []
    
    private var sortedEvents: [SessionEvent] {
        events.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if sortedEvents.isEmpty {
                emptyStateView
            } else {
                timelineContent
            }
        }
    }
    
    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: Theme.spacing3) {
            ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                TimelineEventRow(
                    event: event,
                    isLast: index == sortedEvents.count - 1,
                    isAnimated: animatedEventIds.contains(event.id)
                )
                .onAppear {
                    // Animate new events with fade + slide
                    if !animatedEventIds.contains(event.id) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.1)) {
                            animatedEventIds.insert(event.id)
                        }
                        
                        // Haptic feedback for major events
                        if isMajorEvent(event.type) {
                            HapticFeedback.light()
                        }
                    }
                }
            }
        }
        .padding(.vertical, Theme.spacing2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textSecondary)
            Text("No events yet")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing4)
    }
    
    private func isMajorEvent(_ type: SessionEventType) -> Bool {
        switch type {
        case .sessionStarted, .sessionEnded, .unlockApproved, .unlockDenied:
            return true
        default:
            return false
        }
    }
}

struct TimelineEventRow: View {
    let event: SessionEvent
    let isLast: Bool
    let isAnimated: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacing2) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(iconColor(for: event.type))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: iconName(for: event.type))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Timeline line (if not last)
                if !isLast {
                    Rectangle()
                        .fill(AppColors.textSecondary.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, Theme.spacing)
                }
            }
            .frame(width: 32)
            
            // Event content
            VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                // Title
                Text(title(for: event.type))
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                // Timestamp
                Text(formatTimestamp(event.timestamp))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                // Metadata (if available)
                if let metadata = event.metadata, !metadata.isEmpty {
                    metadataView(metadata)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Theme.spacing)
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(x: isAnimated ? 0 : -20)
    }
    
    private func metadataView(_ metadata: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.smallSpacing) {
            if let bundleId = metadata["bundleId"] {
                HStack(spacing: Theme.smallSpacing) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                    Text(bundleId)
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            if let reason = metadata["reason"] {
                HStack(alignment: .top, spacing: Theme.smallSpacing) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                    Text(reason)
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.top, Theme.smallSpacing)
    }
    
    private func iconName(for type: SessionEventType) -> String {
        switch type {
        case .sessionStarted:
            return "play.circle.fill"
        case .proofSubmitted:
            return "camera.fill"
        case .unlockRequested:
            return "lock.open"
        case .unlockApproved:
            return "checkmark.circle.fill"
        case .unlockDenied:
            return "xmark.circle.fill"
        case .sessionEnded:
            return "stop.circle.fill"
        }
    }
    
    private func iconColor(for type: SessionEventType) -> Color {
        switch type {
        case .sessionStarted:
            return AppColors.success
        case .proofSubmitted:
            return AppColors.anchorAccent
        case .unlockRequested:
            return AppColors.warning
        case .unlockApproved:
            return AppColors.success
        case .unlockDenied:
            return AppColors.error
        case .sessionEnded:
            return AppColors.textSecondary
        }
    }
    
    private func title(for type: SessionEventType) -> String {
        switch type {
        case .sessionStarted:
            return "Session started"
        case .proofSubmitted:
            return "Proof submitted"
        case .unlockRequested:
            return "Unlock requested"
        case .unlockApproved:
            return "Unlock approved"
        case .unlockDenied:
            return "Unlock denied"
        case .sessionEnded:
            return "Session ended"
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

