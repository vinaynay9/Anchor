import SwiftUI

struct SessionSetupView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var mockFriends: [MockFriend] = [
        MockFriend(id: UUID().uuidString, name: "Alice"),
        MockFriend(id: UUID().uuidString, name: "Bob"),
        MockFriend(id: UUID().uuidString, name: "Charlie")
    ]
    
    private let durationOptions = [25, 50, 90]
    
    var body: some View {
        Form {
            Section(header: Text("Duration")) {
                Picker("Duration", selection: $viewModel.selectedDurationMinutes) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Accountability Friends (Optional)")) {
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
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.error)
                }
            }
            
            Button(action: {
                viewModel.startSession()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, Theme.spacing)
                    }
                    Text("Start Session")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading)
        }
        .navigationTitle("New Session")
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

