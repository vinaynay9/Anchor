import SwiftUI
import FamilyControls

struct ActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps to Block")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            HapticFeedback.selectionChanged()
                            dismiss()
                        }
                    }
                }
                .background(AppColors.background)
                .scrollContentBackground(.hidden)
                .tint(AppColors.accent)
                .toolbarBackground(AppColors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
