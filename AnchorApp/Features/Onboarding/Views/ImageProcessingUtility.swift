import Foundation
import CoreImage
import CoreGraphics
import ImageIO
import AVFoundation

func jpegData(from processedImage: CIImage, compression: CGFloat) throws -> Data {
    let ciContext = CIContext()
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    if let cgImage = ciContext.createCGImage(processedImage, from: processedImage.extent, format: .RGBA8, colorSpace: colorSpace) {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, AVFileType.jpeg as CFString, 1, nil) else {
            throw NSError(domain: "ImageProcessing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"]) 
        }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: compression]
        CGImageDestinationAddImage(dest, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw NSError(domain: "ImageProcessing", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize image destination"]) 
        }
        return data as Data
    }
    throw NSError(domain: "ImageProcessing", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage from CIImage"])
}
