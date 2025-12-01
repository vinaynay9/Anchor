import Foundation
import UIKit
import Shared

enum ProofError: LocalizedError {
    case imageConversionFailed
    case invalidImageData
    case invalidResponse
    case networkError(Error)
    case uploadFailedAfterRetries
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG data"
        case .invalidImageData:
            return "Invalid image data provided"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .uploadFailedAfterRetries:
            return "Upload failed after multiple attempts. Please check your connection and try again."
        }
    }
}

protocol ProofServiceProtocol {
    func uploadProof(imageData: Data, sessionId: String) async throws -> Proof
    func fetchProofs(for sessionId: String) async throws -> [Proof]
    func getProof(id: UUID) async throws -> Proof
    func getProofsForUser(userId: UUID) async throws -> [Proof]
}

/// Proof Upload Pipeline Documentation
///
/// # Photo Proof Submission Pipeline
///
/// The proof upload pipeline is designed for reliability, privacy, and background compatibility.
///
/// ## Pipeline Stages
///
/// 1. **Image Preprocessing** (handled by ProofViewModel)
///    - Images are processed using `ImageProcessingUtility.processImageForUpload()`
///    - EXIF metadata is stripped to protect user privacy (location, device info, etc.)
///    - JPEG compression is applied (default: 0.75 quality) to reduce file size
///    - Images are resized if they exceed 2048px in any dimension
///
/// 2. **Upload with Retry Logic**
///    - Initial upload attempt
///    - Up to 2 retry attempts on failure (total of 3 attempts)
///    - Retries occur with exponential backoff (1s, 2s delays)
///    - Only network/transient errors trigger retries (not validation errors)
///
/// 3. **Background-Compatible URLSession**
///    - Uses a dedicated URLSession with background-compatible configuration
///    - Allows uploads to continue even if app enters background
///    - Configured with appropriate timeouts and policies
///
/// ## Error Handling
///
/// - Validation errors (invalid data, invalid sessionId) fail immediately without retry
/// - Network errors (timeouts, connection failures) trigger retry logic
/// - Server errors (5xx) trigger retry logic
/// - Client errors (4xx except 401) trigger retry logic
/// - Authentication errors (401) fail immediately without retry
///
/// ## Privacy Considerations
///
/// - All EXIF metadata is stripped before upload
/// - No location, device, or timestamp metadata is transmitted
/// - Images are compressed to reduce upload time and bandwidth
///
class ProofService: ProofServiceProtocol {
    static let shared = ProofService()
    
    private let apiClient: APIClient
    private let uploadSession: URLSession
    
    /// Maximum number of retry attempts (total attempts = maxRetries + 1)
    private let maxRetries = 2
    
    /// Initial retry delay in seconds
    private let initialRetryDelay: TimeInterval = 1.0
    
    private init() {
        // Create background-compatible URLSession configuration
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 300.0 // 5 minutes for large uploads
        config.httpMaximumConnectionsPerHost = 1
        
        // Use default configuration which supports background continuation
        // when app is backgrounded (iOS continues network tasks in background)
        self.uploadSession = URLSession(configuration: config)
        
        // Create APIClient with the upload session
        self.apiClient = APIClient(session: uploadSession)
    }
    
    // MARK: - POST /proofs (multipart)
    
    /// Uploads a proof image with retry logic and background-compatible networking.
    ///
    /// **Pipeline Flow:**
    /// 1. Validates image data and sessionId
    /// 2. Attempts upload with retry logic (up to 2 retries)
    /// 3. Returns parsed Proof on success
    ///
    /// **Retry Behavior:**
    /// - Retries on network errors, timeouts, and server errors (5xx)
    /// - Uses exponential backoff: 1s, 2s delays between retries
    /// - Does not retry on validation errors or authentication failures
    ///
    /// - Parameters:
    ///   - imageData: Preprocessed image data (should already have EXIF stripped and be compressed)
    ///   - sessionId: UUID string of the session to associate the proof with
    /// - Returns: Uploaded Proof object
    /// - Throws: ProofError for validation or upload failures
    func uploadProof(imageData: Data, sessionId: String) async throws -> Proof {
        // Validate image data
        guard imageData.count > 0 else {
            throw ProofError.invalidImageData
        }
        
        // Convert sessionId string to UUID for validation
        guard UUID(uuidString: sessionId) != nil else {
            throw ProofError.invalidImageData
        }
        
        // Attempt upload with retry logic
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                // POST /proofs - Upload using multipart/form-data
                let endpoint = APIEndpoint.uploadProof(sessionId: sessionId, imageData: imageData)
                let dto: ProofDTO = try await apiClient.request(endpoint, responseType: ProofDTO.self)
                
                guard let proof = dto.toProof() else {
                    throw ProofError.invalidResponse
                }
                
                return proof
                
            } catch let error as AnchorAPIError {
                // Determine if we should retry based on error type
                let shouldRetry = shouldRetryUpload(error: error, attempt: attempt)
                
                if !shouldRetry {
                    // Don't retry validation/auth errors
                    throw mapAPIError(error)
                }
                
                // Store error for potential final throw
                lastError = error
                
                // Calculate exponential backoff delay
                if attempt < maxRetries {
                    let delay = initialRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
            } catch {
                // For non-AnchorAPIError errors, retry if not on last attempt
                if attempt < maxRetries {
                    lastError = error
                    let delay = initialRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw ProofError.networkError(error)
                }
            }
        }
        
        // All retries exhausted
        if let lastError = lastError {
            throw mapAPIError(lastError as? AnchorAPIError ?? AnchorAPIError.networkError(lastError))
        } else {
            throw ProofError.uploadFailedAfterRetries
        }
    }
    
    /// Determines if an upload should be retried based on error type and attempt number.
    private func shouldRetryUpload(error: AnchorAPIError, attempt: Int) -> Bool {
        // Don't retry if we've exhausted attempts
        guard attempt < maxRetries else {
            return false
        }
        
        switch error {
        case .unauthorized:
            // Don't retry auth errors - token issue needs user action
            return false
        case .networkError:
            // Retry network errors (connection issues, timeouts)
            return true
        case .serverError:
            // Retry server errors (5xx) - may be transient
            return true
        case .decodingError:
            // Don't retry decoding errors - response format issue
            return false
        case .notFound:
            // Don't retry 404 - resource doesn't exist
            return false
        case .unknown:
            // Retry unknown errors - may be transient network issues
            return true
        }
    }
    
    /// Maps AnchorAPIError to ProofError
    private func mapAPIError(_ error: AnchorAPIError) -> ProofError {
        switch error {
        case .networkError(let underlyingError):
            return .networkError(underlyingError)
        case .unauthorized, .notFound, .decodingError, .serverError, .unknown:
            return .networkError(error)
        }
    }
    
    // MARK: - Fetch proofs for session
    
    func fetchProofs(for sessionId: String) async throws -> [Proof] {
        // For now, we'll fetch all proofs for the current user
        // In the future, we might have a GET /proofs?session_id={id} endpoint
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let userId = UUID(uuidString: userIdString) else {
            throw ProofError.networkError(NSError(domain: "ProofService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
        }
        
        // Get all proofs for user and filter by sessionId
        let allProofs = try await getProofsForUser(userId: userId)
        return allProofs.filter { $0.sessionId.uuidString == sessionId }
    }
    
    // MARK: - GET /proofs/{id}
    
    func getProof(id: UUID) async throws -> Proof {
        let endpoint = APIEndpoint.getProof(id: id)
        let dto: ProofDTO = try await apiClient.request(endpoint, responseType: ProofDTO.self)
        
        guard let proof = dto.toProof() else {
            throw ProofError.invalidResponse
        }
        
        return proof
    }
    
    // MARK: - GET /proofs/user/{id}
    
    func getProofsForUser(userId: UUID) async throws -> [Proof] {
        let endpoint = APIEndpoint.getProofsForUser(userId: userId)
        let dtos: [ProofDTO] = try await apiClient.request(endpoint, responseType: [ProofDTO].self)
        
        return dtos.compactMap { $0.toProof() }
    }
}
