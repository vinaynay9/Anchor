import SwiftUI
import AVFoundation
import UIKit

/// A SwiftUI wrapper for `CameraViewController` that provides camera capture functionality.
///
/// This `UIViewControllerRepresentable` bridges UIKit's `AVFoundation` camera APIs with SwiftUI,
/// allowing seamless integration of live camera preview and photo capture into SwiftUI views.
///
/// ## Integration with SwiftUI
/// - Use this view directly in SwiftUI hierarchies (e.g., in sheets, navigation stacks)
/// - The view automatically manages the underlying `UIViewController` lifecycle
/// - Camera session starts when the view appears and stops when it disappears
///
/// ## Permission Requirements
/// - **Camera Permission**: Required (`NSCameraUsageDescription` must be set in Info.plist)
/// - The app must request camera authorization before this view is presented
/// - If permission is denied, the delegate's `didFailWithError` callback will be invoked
///
/// ## Callback Behavior
/// - **Success**: When a photo is captured, `capturedImage` binding is updated with the `UIImage`
/// - **Error**: Camera errors are reported via the delegate's `didFailWithError` method
/// - **Capture Trigger**: Set `isCapturing` to `true` to trigger a photo capture
///
/// ## UIViewController Lifecycle
/// - `viewDidLoad`: Camera setup and configuration
/// - `viewWillAppear`: Camera session starts running
/// - `viewWillDisappear`: Camera session stops to preserve resources
/// - `viewDidLayoutSubviews`: Preview layer frame is updated to match view bounds
struct CameraView: UIViewControllerRepresentable {
    /// Binding to the captured image. Updated when photo capture succeeds.
    @Binding var capturedImage: UIImage?
    
    /// Binding that triggers photo capture when set to `true`. Automatically reset to `false` after capture.
    @Binding var isCapturing: Bool
    
    // MARK: - UIViewControllerRepresentable Implementation
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if isCapturing {
            uiViewController.capturePhoto()
            DispatchQueue.main.async {
                isCapturing = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    /// Coordinates communication between the UIKit view controller and SwiftUI view.
    /// Handles camera capture callbacks and error reporting.
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        /// Called when a photo is successfully captured.
        /// Updates the `capturedImage` binding with the captured image.
        func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
            parent.capturedImage = image
        }
        
        /// Called when a camera error occurs.
        /// Currently logs to console; consider enhancing to show user-facing error messages.
        func cameraViewController(_ controller: CameraViewController, didFailWithError error: Error) {
            print("Camera error: \(error.localizedDescription)")
        }
    }
}

// MARK: - CameraViewControllerDelegate Protocol

/// Delegate protocol for camera view controller events.
/// Implemented by `CameraView.Coordinator` to bridge UIKit callbacks to SwiftUI.
protocol CameraViewControllerDelegate: AnyObject {
    /// Called when a photo is successfully captured.
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    
    /// Called when a camera error occurs during setup or capture.
    func cameraViewController(_ controller: CameraViewController, didFailWithError error: Error)
}

// MARK: - CameraViewController

/// UIKit view controller that manages the camera capture session and preview.
///
/// This controller handles:
/// - Camera device configuration and session setup
/// - Live preview layer management
/// - Photo capture with HEVC support when available
/// - Session lifecycle (start/stop) based on view appearance
///
/// ## Permission Requirements
/// - Camera permission must be granted before the session can start
/// - Permission check is performed before starting the capture session
///
/// ## Lifecycle Notes
/// - Session starts in `viewWillAppear` to ensure camera is ready when visible
/// - Session stops in `viewWillDisappear` to preserve battery and resources
/// - Preview layer frame is updated in `viewDidLayoutSubviews` to match view bounds
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    // MARK: - Private Properties
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update preview layer frame to match view bounds when layout changes
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    // MARK: - Camera Setup
    
    /// Configures the camera capture session with back camera input and photo output.
    /// Sets up the preview layer for live camera feed display.
    ///
    /// - Note: This method does not start the session. Call `startSession()` separately.
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            delegate?.cameraViewController(self, didFailWithError: NSError(domain: "CameraError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Camera not available"]))
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            photoOutput = output
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        captureSession = session
    }
    
    // MARK: - Photo Capture
    
    /// Captures a photo using the current camera session.
    /// Uses HEVC codec if available for better compression.
    ///
    /// - Note: This method should only be called when the session is running.
    /// - The captured image is delivered via `AVCapturePhotoCaptureDelegate` callback.
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Session Management
    
    /// Starts the camera capture session on a background queue.
    /// Checks camera permission before starting.
    ///
    /// - Note: Session operations are performed on a background queue to avoid blocking the main thread.
    private func startSession() {
        // Check camera permission before starting session
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard authStatus == .authorized else {
            let error = NSError(
                domain: "CameraError",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Camera permission not granted. Status: \(authStatus.rawValue)"]
            )
            delegate?.cameraViewController(self, didFailWithError: error)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    /// Stops the camera capture session on a background queue.
    ///
    /// - Note: Called automatically when the view disappears to preserve battery and resources.
    private func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    /// Called when photo capture processing completes.
    /// Converts the captured photo data to a `UIImage` and notifies the delegate.
    ///
    /// - Parameters:
    ///   - output: The photo output that captured the photo
    ///   - photo: The captured photo data
    ///   - error: Error if capture failed, nil if successful
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            delegate?.cameraViewController(self, didFailWithError: error)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            delegate?.cameraViewController(self, didFailWithError: NSError(domain: "CameraError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"]))
            return
        }
        
        delegate?.cameraViewController(self, didCaptureImage: image)
    }
}
