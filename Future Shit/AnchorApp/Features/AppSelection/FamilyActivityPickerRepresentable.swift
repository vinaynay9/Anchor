import SwiftUI
import FamilyControls

/// A SwiftUI wrapper for presenting `FamilyActivityPicker` in modal sheets.
///
/// This wrapper provides a clean abstraction around Apple's `FamilyActivityPicker` SwiftUI view,
/// adding navigation controls, styling, and callback handling for app selection workflows.
///
/// ## Integration with SwiftUI
/// - Designed to be presented as a sheet (`.sheet(isPresented:)` modifier)
/// - Uses `NavigationView` to provide navigation bar with Cancel/Done buttons
/// - Automatically handles dismissal via `@Environment(\.dismiss)`
///
/// ## Permission Requirements
/// - **Screen Time Permission**: Required (`FamilyControls` framework authorization)
/// - The app must request Screen Time authorization via `AuthorizationCenter` before presenting this picker
/// - Authorization should be checked before showing this view (see `ScreenTimeService`)
///
/// ## Usage
/// ```swift
/// @State private var showPicker = false
/// @State private var selection = FamilyActivitySelection()
///
/// .sheet(isPresented: $showPicker) {
///     FamilyActivityPickerWrapper(selection: $selection) {
///         // Handle selection callback
///         saveSelection(selection)
///     }
/// }
/// ```
///
/// ## Selection Callback Behavior
/// - When user taps "Done", the `onDismiss` closure is called with the current selection
/// - The `selection` binding is automatically updated by `FamilyActivityPicker` as user makes selections
/// - The view dismisses after the callback executes
/// - If user taps "Cancel", the view dismisses without calling `onDismiss`
///
/// ## Note: UI-Only Component
/// - This is a presentation wrapper only; it does not handle Screen Time authorization
/// - Actual app blocking/shielding is handled by `ScreenTimeService` and `ManagedSettings`
/// - The selection data (`FamilyActivitySelection`) must be persisted separately if needed
struct FamilyActivityPickerWrapper: View {
    /// Binding to the selected apps and categories.
    /// Updated automatically by `FamilyActivityPicker` as user makes selections.
    @Binding var selection: FamilyActivitySelection
    
    /// Environment value for dismissing the sheet.
    @Environment(\.dismiss) var dismiss
    
    /// Optional callback invoked when user taps "Done".
    /// Called before the view dismisses, allowing parent to handle the selection.
    var onDismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps to Block")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(AppColors.textPrimary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            // Invoke callback before dismissing to allow parent to process selection
                            onDismiss?()
                            dismiss()
                        }
                        .foregroundColor(AppColors.anchorAccent)
                        .fontWeight(.semibold)
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}

