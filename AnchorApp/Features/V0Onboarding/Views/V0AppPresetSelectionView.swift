import SwiftUI
import FamilyControls
import Shared

struct V0AppPresetSelectionView: View {
    @State private var selection: V0AppSelection = AppGroupStorage.shared.getV0AppSelection()
    @State private var presetStates: [V0AppBucket: Bool] = [:]
    @State private var hintText: String?

    let onContinue: () -> Void

    private let storage = AppGroupStorage.shared
    private let bucketing = V0AppBucketingService.shared

    private let presetBuckets: [V0AppBucket] = [
        .social,
        .games,
        .sports,
        .entertainmentStreaming,
        .shopping
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested presets")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Pick common buckets to block. Presets use Apple categories when available, with bundle-ID fallbacks.")
                .foregroundColor(AppColors.textSecondary)

            ForEach(presetBuckets, id: \.self) { bucket in
                Toggle(isOn: Binding(
                    get: { presetStates[bucket] ?? false },
                    set: { value in
                        presetStates[bucket] = value
                        updatePreset(bucket: bucket, enabled: value)
                    }
                )) {
                    Text(label(for: bucket))
                        .foregroundColor(AppColors.textPrimary)
                }
                .tint(AppColors.accent)
            }

            if let hintText {
                Text(hintText)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textTertiary)
            }

            Button(action: saveAndContinue) {
                Text("Continue to app selection")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 12)

            Spacer()
        }
        .padding()
        .applyV0Theme()
        .onAppear(perform: loadState)
    }

    private func loadState() {
        selection = storage.getV0AppSelection()
        var newStates: [V0AppBucket: Bool] = [:]
        for bucket in presetBuckets {
            let tokens = bucketing.presetTokens(for: bucket, selection: selection)
            newStates[bucket] = !tokens.categories.isEmpty || !tokens.applications.isEmpty
        }
        presetStates = newStates
    }

    private func updatePreset(bucket: V0AppBucket, enabled: Bool) {
        var current = selection
        let tokens = bucketing.presetTokens(for: bucket, selection: current)

        if enabled {
            if tokens.categories.isEmpty && tokens.applications.isEmpty {
                hintText = "Select apps or categories to enable presets."
                return
            }
            hintText = nil
            let newCategoryTokens = storage.decodeCategoryTokens(current.blockedCategories).union(tokens.categories)
            let newAppTokens = storage.decodeApplicationTokens(current.blockedApplications).union(tokens.applications)
            current.blockedCategories = storage.encodeCategoryTokens(newCategoryTokens)
            current.blockedApplications = storage.encodeApplicationTokens(newAppTokens)
        } else {
            hintText = nil
            let remainingCategories = storage.decodeCategoryTokens(current.blockedCategories).subtracting(tokens.categories)
            let remainingApps = storage.decodeApplicationTokens(current.blockedApplications).subtracting(tokens.applications)
            current.blockedCategories = storage.encodeCategoryTokens(remainingCategories)
            current.blockedApplications = storage.encodeApplicationTokens(remainingApps)
        }

        selection = current
        storage.setV0AppSelection(current)
    }

    private func saveAndContinue() {
        storage.setV0AppSelection(selection)
        onContinue()
    }

    private func label(for bucket: V0AppBucket) -> String {
        switch bucket {
        case .social: return "Block Social"
        case .games: return "Block Games"
        case .sports: return "Block Sports"
        case .entertainmentStreaming: return "Block Entertainment"
        case .shopping: return "Block Shopping"
        default: return "Block \(bucket.title)"
        }
    }
}
