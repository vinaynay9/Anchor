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
                            dismiss()
                        }
                    }
                }
        }
    }
}

