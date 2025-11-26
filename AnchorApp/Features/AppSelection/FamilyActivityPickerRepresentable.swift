import SwiftUI
import FamilyControls

/// A clean wrapper view for presenting FamilyActivityPicker in sheets
/// Since FamilyActivityPicker is a SwiftUI view, this provides a clean abstraction
/// with proper styling and navigation controls
struct FamilyActivityPickerWrapper: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) var dismiss
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
                            onDismiss?()
                            dismiss()
                        }
                        .foregroundColor(AppColors.accent)
                        .fontWeight(.semibold)
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}

