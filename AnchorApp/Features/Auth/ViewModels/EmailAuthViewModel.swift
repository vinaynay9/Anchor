import Foundation
import Shared

@MainActor
final class EmailAuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }

    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    var isPasswordValid: Bool {
        let pwd = password
        guard pwd.count >= 8 else { return false }
        let hasLetter = pwd.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = pwd.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = pwd.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        return hasLetter && hasNumber && hasSpecial
    }

    var isConfirmValid: Bool {
        !confirmPassword.isEmpty && confirmPassword == password
    }

    var canSignUp: Bool {
        isEmailValid && isPasswordValid && isConfirmValid && !isLoading
    }

    var canSignIn: Bool {
        isEmailValid && !password.isEmpty && !isLoading
    }

    func signUp() async -> User? {
        guard canSignUp else { return nil }
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signUp(email: email, password: password)
            isLoading = false
            return user
        } catch {
            isLoading = false
            errorMessage = mapError(error)
            return nil
        }
    }

    func signIn() async -> User? {
        guard canSignIn else { return nil }
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signIn(email: email, password: password)
            isLoading = false
            return user
        } catch {
            isLoading = false
            errorMessage = mapError(error)
            return nil
        }
    }

    private func mapError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            switch authError {
            case .invalidCredentials:
                return "Invalid email or password."
            case .networkError:
                return "Network error. Please try again."
            case .notAuthenticated:
                return "Authentication failed. Please try again."
            default:
                return "Sign in failed. Please try again."
            }
        }
        return error.localizedDescription
    }
}
