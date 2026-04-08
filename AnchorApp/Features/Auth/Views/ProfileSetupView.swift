import SwiftUI
import Shared

// MARK: - Profile Setup View Model

@MainActor
final class ProfileSetupViewModel: ObservableObject {

    // MARK: - Published State
    @Published var firstName: String
    @Published var lastName: String
    @Published var birthday: Date
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userService = UserService.shared
    private let logger = LoggerService.shared

    // MARK: - Age Validation
    static let minimumAge = 13

    static var latestAllowedBirthday: Date {
        Calendar.current.date(byAdding: .year, value: -minimumAge, to: Date()) ?? Date()
    }

    var isBirthdayValid: Bool {
        birthday <= Self.latestAllowedBirthday
    }

    var canContinue: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && isBirthdayValid
        && !isLoading
    }

    // MARK: - Init

    init(prefillFirstName: String? = nil, prefillLastName: String? = nil) {
        self.firstName = prefillFirstName ?? ""
        self.lastName  = prefillLastName  ?? ""
        // Default: 18 years ago (well above the 13-year minimum)
        self.birthday  = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    // MARK: - Save

    /// Persists name + birthday locally and attempts a backend sync.
    /// Returns true on local success; backend errors are swallowed so the user
    /// can continue offline and sync later.
    func save() async -> Bool {
        let trimFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimLast  = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimFirst.isEmpty, !trimLast.isEmpty, isBirthdayValid else { return false }

        isLoading    = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.calendar  = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        let birthdayString = formatter.string(from: birthday)

        // ── 1. Persist to AppGroupStorage (local, shared with extension) ──
        AppGroupStorage.shared.setPersonalInfo(
            firstName: trimFirst,
            lastName:  trimLast,
            birthday:  birthdayString
        )

        let displayName = "\(trimFirst) \(trimLast)"
        let calendar    = Calendar(identifier: .gregorian)
        let month       = calendar.component(.month, from: birthday)
        let day         = calendar.component(.day,   from: birthday)
        AppGroupStorage.shared.setProfile(
            displayName: displayName,
            birthMonth:  month,
            birthDay:    day,
            timezone:    TimeZone.current.identifier
        )
        logger.logInfo("Profile setup: saved to AppGroupStorage", category: "Auth")

        // ── 2. TODO: [Supabase Migration] Upsert to `users` table ────────
        //
        // Signature to implement when Supabase is wired up:
        //   func upsertProfile(
        //       firstName:  String,
        //       lastName:   String,
        //       birthday:   String,      // "yyyy-MM-dd"
        //       displayName: String,
        //       timezone:   String
        //   ) async throws
        //
        // Example call:
        //   try await SupabaseClient.shared
        //       .from("users")
        //       .upsert([
        //           "first_name":   trimFirst,
        //           "last_name":    trimLast,
        //           "birthday":     birthdayString,
        //           "display_name": displayName,
        //           "timezone":     TimeZone.current.identifier
        //       ])
        //       .execute()

        // ── 3. Best-effort backend sync (legacy AWS endpoint) ─────────────
        do {
            _ = try await userService.updateUserProfile(
                displayName: displayName,
                birthMonth:  month,
                birthDay:    day,
                timezone:    TimeZone.current.identifier,
                email:       nil,
                firstName:   trimFirst,
                lastName:    trimLast,
                birthday:    birthdayString
            )
            logger.logInfo("Profile setup: backend sync succeeded", category: "Auth")
        } catch {
            // Non-fatal: local save succeeded. Will retry on next launch / Supabase migration.
            logger.logWarning(
                "Profile setup: backend sync failed (offline-tolerant): \(error.localizedDescription)",
                category: "Auth"
            )
        }

        isLoading = false
        return true
    }
}

// MARK: - Profile Setup View

struct ProfileSetupView: View {

    @StateObject private var viewModel: ProfileSetupViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

    @State private var showContent = false
    @State private var showAgeError = false

    enum Field { case firstName, lastName }

    let onComplete: () -> Void

    // MARK: - Init

    init(
        prefillFirstName: String? = nil,
        prefillLastName:  String? = nil,
        onComplete: @escaping () -> Void
    ) {
        _viewModel   = StateObject(
            wrappedValue: ProfileSetupViewModel(
                prefillFirstName: prefillFirstName,
                prefillLastName:  prefillLastName
            )
        )
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 72)

                    // ── Header ───────────────────────────────────────────
                    VStack(spacing: 8) {
                        Text("Your Profile")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text("A few details to personalise your experience.")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing5)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)

                    Spacer().frame(height: Theme.spacing5)

                    // ── Fields ───────────────────────────────────────────
                    VStack(spacing: Theme.spacing2) {
                        focusableField(
                            placeholder: "First name",
                            text: $viewModel.firstName,
                            field: .firstName,
                            contentType: .givenName
                        )

                        focusableField(
                            placeholder: "Last name",
                            text: $viewModel.lastName,
                            field: .lastName,
                            contentType: .familyName
                        )

                        birthdayRow
                    }
                    .padding(.horizontal, Theme.spacing3)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 12)

                    // Age-validation hint
                    if showAgeError {
                        Text("You must be \(ProfileSetupViewModel.minimumAge) or older to use Anchor.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                            .padding(.top, Theme.spacing)
                            .padding(.horizontal, Theme.spacing3)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                            .padding(.top, Theme.spacing)
                            .padding(.horizontal, Theme.spacing3)
                    }

                    Spacer().frame(height: Theme.spacing5)

                    // ── Continue button ──────────────────────────────────
                    Button {
                        focusedField = nil
                        handleContinue()
                    } label: {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView().tint(AppColors.textPrimary)
                            } else {
                                Text("Continue")
                                    .font(AppTypography.button)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(continueButtonBackground)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(!viewModel.canContinue)
                    .padding(.horizontal, Theme.spacing3)
                    .opacity(showContent ? 1 : 0)

                    Spacer().frame(height: 48)
                }
            }
        }
        .ignoresSafeArea()
        .onTapGesture { focusedField = nil }
        .onAppear {
            if reduceMotion {
                showContent = true
            } else {
                withAnimation(AppMotion.gentleSpring.delay(0.1)) { showContent = true }
            }
        }
        .onChange(of: viewModel.birthday) { _ in
            withAnimation(AppMotion.snappy) {
                showAgeError = !viewModel.isBirthdayValid
            }
        }
    }

    // MARK: - Reusable focused text field

    @ViewBuilder
    private func focusableField(
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType
    ) -> some View {
        let isFocused = focusedField == field
        TextField(placeholder, text: text)
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            .textContentType(contentType)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($focusedField, equals: field)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(
                                isFocused ? AppColors.accent.opacity(0.7) : AppColors.border.opacity(0.45),
                                lineWidth: isFocused ? 1.5 : 1
                            )
                    )
            )
            .animation(AppMotion.snappy, value: isFocused)
    }

    // MARK: - Birthday row

    private var birthdayRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Birthday")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                DatePicker(
                    "",
                    selection: $viewModel.birthday,
                    in: ...ProfileSetupViewModel.latestAllowedBirthday,
                    displayedComponents: .date
                )
                .labelsHidden()
                .colorScheme(.dark)
            }
            Spacer()
        }
        .padding(.vertical, Theme.spacing2)
        .padding(.horizontal, Theme.spacing2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.border.opacity(0.45), lineWidth: 1)
                )
        )
    }

    // MARK: - Continue button background (gradient pill)

    private var continueButtonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(viewModel.canContinue ? AppColors.accent : AppColors.accent.opacity(0.35))
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        }
        .shadow(
            color: viewModel.canContinue ? AppColors.accent.opacity(0.45) : .clear,
            radius: 20, x: 0, y: 8
        )
        .animation(AppMotion.snappy, value: viewModel.canContinue)
    }

    // MARK: - Actions

    private func handleContinue() {
        guard viewModel.canContinue else {
            // Birthday picker already limits selection, but guard against edge cases.
            withAnimation(AppMotion.snappy) { showAgeError = !viewModel.isBirthdayValid }
            return
        }
        Task {
            let ok = await viewModel.save()
            if ok {
                onComplete()
            } else {
                viewModel.errorMessage = "Could not save your profile. Please try again."
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupView(
        prefillFirstName: "Jane",
        prefillLastName:  "Doe",
        onComplete: {}
    )
}
