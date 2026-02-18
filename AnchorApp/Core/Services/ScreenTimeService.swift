import Foundation
import FamilyControls
import ManagedSettings
import Shared

enum ScreenTimeError: Error, LocalizedError {
    case authorizationDenied
    case authorizationFailed
    case authorizationRestricted
    case entitlementMissing
    case familyControlsUnavailable(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time authorization was denied. Please enable it in Settings."
        case .authorizationFailed:
            return "Failed to request Screen Time authorization."
        case .authorizationRestricted:
            return "Screen Time is restricted on this device (possibly by parental controls)."
        case .entitlementMissing:
            return "FamilyControls entitlement is not available. Please contact support."
        case .familyControlsUnavailable(let underlying):
            if let error = underlying {
                return "FamilyControls is unavailable: \(error.localizedDescription)"
            }
            return "FamilyControls is unavailable on this device."
        }
    }
}

final class ScreenTimeService: ScreenTimeServiceProtocol {
    static let shared = ScreenTimeService()

    private let authorizationCenter = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let storage = AppGroupStorage.shared

    private init() {}

    func requestAuthorization() async throws {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
        } catch let error as NSError {
            if error.domain.contains("FamilyControls") {
                switch error.code {
                case 0:
                    throw ScreenTimeError.authorizationRestricted
                case 1:
                    throw ScreenTimeError.familyControlsUnavailable(underlying: error)
                case 2, 4, 5:
                    throw ScreenTimeError.authorizationDenied
                case 3, 6:
                    throw ScreenTimeError.authorizationFailed
                default:
                    break
                }
            }

            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("entitlement") ||
               errorDescription.contains("not entitled") ||
               errorDescription.contains("missing capability") {
                throw ScreenTimeError.entitlementMissing
            }

            if errorDescription.contains("denied") || errorDescription.contains("cancel") {
                throw ScreenTimeError.authorizationDenied
            }

            throw ScreenTimeError.familyControlsUnavailable(underlying: error)
        } catch {
            throw ScreenTimeError.familyControlsUnavailable(underlying: error)
        }
    }

    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus {
        switch authorizationCenter.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .approved:
            return .approved
        @unknown default:
            return .denied
        }
    }

    func isAuthorized() -> Bool {
        authorizationCenter.authorizationStatus == .approved
    }

    func applyBlockingFromStorage() {
        let selection = storage.getV0AppSelection()
        applyBlocking(selection: selection)
    }

    func applyBlocking(selection: V0AppSelection) {
        let blockedApps = storage.decodeApplicationTokens(selection.blockedApplications)
        let blockedCategories = storage.decodeCategoryTokens(selection.blockedCategories)

        if blockedApps.isEmpty && blockedCategories.isEmpty {
            clearBlocking()
            return
        }

        store.shield.applications = blockedApps.isEmpty ? nil : blockedApps
        store.shield.applicationCategories = blockedCategories.isEmpty ? nil : .specific(blockedCategories)
        store.shield.webDomains = nil

        storage.setV0IsLocked(true)
    }

    func applyTemporaryAllowance(allowedApplications: Set<ApplicationToken>) {
        let selection = storage.getV0AppSelection()
        let blockedApps = storage.decodeApplicationTokens(selection.blockedApplications)
        let remainingBlocked = blockedApps.subtracting(allowedApplications)

        store.shield.applications = remainingBlocked.isEmpty ? nil : remainingBlocked
        // Category blocking is removed during temporary allowance because per-app category allowlisting is unreliable.
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        storage.setV0IsLocked(false)
    }

    func clearBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        storage.setV0IsLocked(false)
    }
}
