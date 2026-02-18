import SwiftUI
import FamilyControls
import Shared

struct V0AppSelectionView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var errorMessage: String?
    @State private var isAuthorized = false

    let onFinish: () -> Void

    private let storage = AppGroupStorage.shared
    private let screenTimeService = ScreenTimeService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select apps and categories")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Choose what Anchor should block. Categories are preferred when available.")
                .foregroundColor(AppColors.textSecondary)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textTertiary)
            }

            if !isAuthorized {
                Button("Enable Screen Time") {
                    Task {
                        do {
                            try await screenTimeService.requestAuthorization()
                            isAuthorized = screenTimeService.isAuthorized()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            SolidCard {
                FamilyActivityPicker(selection: $selection)
                    .frame(maxHeight: 360)
                    .onChange(of: selection, perform: { _ in
                        persistSelection()
                    })
            }

            Button(action: finishOnboarding) {
                Text("Finish")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 12)

            Spacer()
        }
        .padding()
        .applyV0Theme()
        .onAppear {
            isAuthorized = screenTimeService.isAuthorized()
            loadSelection()
        }
    }

    private func loadSelection() {
        let stored = storage.getV0AppSelection()
        var restored = FamilyActivitySelection()
        restored.applicationTokens = storage.decodeApplicationTokens(stored.blockedApplications)
        restored.categoryTokens = storage.decodeCategoryTokens(stored.blockedCategories)
        selection = restored
    }

    private func persistSelection() {
        var stored = storage.getV0AppSelection()
        stored.blockedApplications = storage.encodeApplicationTokens(selection.applicationTokens)
        stored.blockedCategories = storage.encodeCategoryTokens(selection.categoryTokens)
        stored.perGoalUnlockedApplications = stored.blockedApplications
        // Apple categories are used when chosen; per-app category is not reliably queryable, so bundle-id heuristics are fallback.
        // We keep any previously stored token->bundleID mapping, but cannot populate it from FamilyActivityPicker alone.
        storage.setV0AppSelection(stored)
    }

    private func finishOnboarding() {
        persistSelection()
        onFinish()
    }
}
