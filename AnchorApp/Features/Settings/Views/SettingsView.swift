import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = viewModel.currentUser {
                        HStack {
                            Text("Username")
                            Spacer()
                            Text(user.username)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        if let displayName = user.displayName {
                            HStack {
                                Text("Display Name")
                                Spacer()
                                Text(displayName)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
                
                Section("Permissions") {
                    NavigationLink(destination: ScreenTimePermissionView()) {
                        Text("Screen Time")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Text("Notifications")
                    }
                }
                
                Section("Actions") {
                    Button(action: {
                        viewModel.signOut()
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(AppColors.error)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadCurrentUser()
            }
        }
    }
}

