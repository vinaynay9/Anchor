import SwiftUI
import FamilyControls

struct SessionSetupView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var mockFriends: [MockFriend] = [
        MockFriend(id: UUID().uuidString, name: "Alice"),
        MockFriend(id: UUID().uuidString, name: "Bob"),
        MockFriend(id: UUID().uuidString, name: "Charlie")
    ]
    @State private var showActivityPicker = false
    @State private var activitySelection = FamilyActivitySelection()
    @State private var hasSelectedApps = false
    
    private let durationOptions = [25, 50, 90]
    private let activitySelectionService = ActivitySelectionService.shared
    
    var body: some View {
        Form {
            Section(header: Text("Duration")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)) {
                Picker("Duration", selection: $viewModel.selectedDurationMinutes) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .listRowBackground(AppColors.secondaryBackground)
            
            Section(header: Text("Apps to Block")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)) {
                Button(action: {
                    showActivityPicker = true
                }) {
                    HStack {
                        Text(hasSelectedApps ? "Change App Selection" : "Select Apps to Block")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if hasSelectedApps {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.anchorAccent)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .listRowBackground(AppColors.secondaryBackground)
            
            Section(header: Text("Accountability Friends (Optional)")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)) {
                ForEach(mockFriends) { friend in
                    Toggle(isOn: Binding(
                        get: { viewModel.selectedFriendIds.contains(friend.id) },
                        set: { isSelected in
                            if isSelected {
                                if !viewModel.selectedFriendIds.contains(friend.id) {
                                    viewModel.selectedFriendIds.append(friend.id)
                                }
                            } else {
                                viewModel.selectedFriendIds.removeAll { $0 == friend.id }
                            }
                        }
                    )) {
                        Text(friend.name)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .tint(AppColors.anchorAccent)
                }
            }
            .listRowBackground(AppColors.secondaryBackground)
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.error)
                }
                .listRowBackground(AppColors.secondaryBackground)
            }
            
            Button(action: {
                Task {
                    await viewModel.startSession()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                            .padding(.trailing, Theme.spacing)
                    }
                    Text("Start Session")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading)
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("New Session")
        .sheet(isPresented: $showActivityPicker) {
            ActivityPickerView(selection: $activitySelection)
                .onDisappear {
                    // Save selection when picker is dismissed
                    do {
                        try activitySelectionService.saveSelection(activitySelection)
                        hasSelectedApps = !activitySelection.applicationTokens.isEmpty
                    } catch {
                        // Handle error silently or show alert
                        print("Failed to save activity selection: \(error)")
                    }
                }
        }
        .onAppear {
            // Load existing selection
            if let existingSelection = activitySelectionService.loadSelection() {
                activitySelection = existingSelection
                hasSelectedApps = !existingSelection.applicationTokens.isEmpty
            }
        }
        .onChange(of: viewModel.activeSession) { session in
            if session != nil {
                dismiss()
            }
        }
    }
}

// Mock friend struct for placeholder implementation
struct MockFriend: Identifiable {
    let id: String
    let name: String
}

