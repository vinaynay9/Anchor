import Foundation
import UIKit
import ImageIO
import CoreImage

/// Utility for processing images before upload to ensure privacy and reliability.
/// Handles EXIF metadata stripping and JPEG compression.
enum ImageProcessingUtility {
    
    /// Default JPEG compression quality (0.0 to 1.0)
    /// Balanced between file size and image quality
    static let defaultCompressionQuality: CGFloat = 0.75
    
    /// Maximum image dimension to prevent oversized uploads
    static let maxImageDimension: CGFloat = 2048
    
    /// Processes an image by stripping EXIF metadata and compressing it.
    /// - Parameters:
    ///   - image: The source UIImage to process
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0). Defaults to 0.75
    /// - Returns: Processed image data with EXIF stripped and compressed, or nil if processing fails
    static func processImageForUpload(_ image: UIImage, compressionQuality: CGFloat = defaultCompressionQuality) -> Data? {
        // Step 1: Resize if necessary to reduce file size
        let resizedImage = resizeImageIfNeeded(image, maxDimension: maxImageDimension)
        
        // Step 2: Strip EXIF metadata and compress
        return createStrippedJPEGData(from: resizedImage, compressionQuality: compressionQuality)
    }
    
    /// Resizes an image if it exceeds the maximum dimension while maintaining aspect ratio.
    /// - Parameters:
    ///   - image: The image to resize
    ///   - maxDimension: Maximum width or height
    /// - Returns: Resized image or original if no resize needed
    private static func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSize = max(size.width, size.height)
        
        // No resize needed if image is already smaller
        guard maxSize > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let scale = maxDimension / maxSize
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Create graphics context and draw resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    /// Creates JPEG data from UIImage with all EXIF metadata stripped.
    /// Uses Core Image to ensure no metadata is preserved.
    /// - Parameters:
    ///   - image: The image to convert
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: JPEG data with no EXIF metadata, or nil if conversion fails
    private static func createStrippedJPEGData(from image: UIImage, compressionQuality: CGFloat) -> Data? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        // Create a new CIImage from the CGImage
        let ciImage = CIImage(cgImage: cgImage)
        
        // Create a CIContext for rendering
        let context = CIContext(options: [
            .useSoftwareRenderer: false,
            .workingColorSpace: CGColorSpaceCreateDeviceRGB()
        ])
        
        // Render to JPEG with compression, which automatically strips all metadata
        guard let colorSpace = cgImage.colorSpace else {
            // Fallback to standard JPEG conversion if color space is unavailable
            return image.jpegData(compressionQuality: compressionQuality)
        }
        
        let qualityKey = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)
        guard let jpegData = context.jpegRepresentation(
            of: ciImage,
            colorSpace: colorSpace,
            options: [qualityKey: compressionQuality]
        ) else {
            // Fallback to standard JPEG conversion if Core Image fails
            return image.jpegData(compressionQuality: compressionQuality)
        }
        
        return jpegData
    }
}
