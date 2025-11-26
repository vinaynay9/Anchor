import ManagedSettingsUI
import SwiftUI

// MARK: - Shield Configuration Extension
// This is the main entry point for the Screen Time shield extension

@main
struct ShieldExtension: ShieldConfigurationDelegate {
    func shieldConfiguration(
        _ configuration: ShieldConfiguration,
        completionHandler: @escaping (ShieldAction) -> Void
    ) {
        // The system will display the ShieldView when a blocked app is opened
        // ShieldView is configured in the extension's Info.plist
    }
}

// MARK: - Shield Configuration View Provider
// This provides the actual view shown on the shield screen

struct ShieldConfigurationView: View {
    let context: ShieldConfigurationContext
    @StateObject private var viewModel = ShieldViewModel()
    
    var body: some View {
        ShieldView(context: context)
    }
}

