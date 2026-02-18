import SwiftUI

struct V0SettingsView: View {
    @StateObject private var viewModel = V0SettingsViewModel()

    var body: some View {
        List {
            NavigationLink("Daily reset time") {
                V0ResetTimeView(viewModel: viewModel)
            }
            .listRowBackground(AppColors.surface)
        }
        .foregroundColor(AppColors.textPrimary)
        .scrollContentBackground(.hidden)
        .background(AppColors.screenBackground)
        .navigationTitle("Settings")
        .applyV0Theme()
        .onAppear {
            viewModel.refresh()
        }
    }
}
