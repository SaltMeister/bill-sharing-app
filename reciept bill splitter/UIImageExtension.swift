import SwiftUI
import UIKit
import Vision
import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
func drawRectangleOnImage(image: UIImage, corners: [CGPoint]) -> UIImage? {
    // Begin a graphics context
    UIGraphicsBeginImageContext(image.size)
    
    // Draw the original image as the background
    image.draw(at: CGPoint.zero)
    
    // Set up the line attributes
    let context = UIGraphicsGetCurrentContext()
    context?.setLineWidth(5.0)
    context?.setStrokeColor(UIColor.red.cgColor)
    
    // Create a path for the rectangle
    let rectanglePath = UIBezierPath()
    
    // Move to the first corner
    rectanglePath.move(to: corners[0])
    
    // Draw lines to the other corners
    for i in 1..<corners.count {
        rectanglePath.addLine(to: corners[i])
    }
    
    // Close the path to create a complete rectangle
    rectanglePath.close()
    
    // Draw the path
    rectanglePath.stroke()
    
    // Extract the image
    let resultImage = UIGraphicsGetImageFromCurrentImageContext()
    
    // End the graphics context
    UIGraphicsEndImageContext()
    
    return resultImage
}

// UIImage extension for resizing and binarization
extension UIImage {
 
    func applyPerspectiveCorrection(to image: CIImage, withFeatures features: [String: CIVector]) -> CIImage? {
        // Convert points from UIKit to Core Image coordinate system
        let convertedFeatures = convertPointsForCoreImage(features, imageSize: image.extent.size)

           guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
           filter.setValue(image, forKey: kCIInputImageKey)
           filter.setValue(convertedFeatures["inputTopLeft"], forKey: "inputTopLeft")
           filter.setValue(convertedFeatures["inputTopRight"], forKey: "inputTopRight")
           filter.setValue(convertedFeatures["inputBottomLeft"], forKey: "inputBottomLeft")
           filter.setValue(convertedFeatures["inputBottomRight"], forKey: "inputBottomRight")

           guard let correctedImage = filter.outputImage else { return nil }

           // Apply a corrective transformation if the resulting image is mirrored
           return correctedImage
    }
    func flipImageVertically(_ image: CIImage) -> CIImage {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -image.extent.height)
        return image.transformed(by: transform)
    }
    func convertPointsForCoreImage(_ points: [String: CIVector], imageSize: CGSize) -> [String: CIVector] {
        var convertedPoints = [String: CIVector]()
        
        for (key, point) in points {
            // Flip the y-coordinate to convert from UIKit to Core Image coordinate system
            let convertedPoint = CIVector(x: point.x, y: imageSize.height - point.y)
            convertedPoints[key] = convertedPoint
        }
        
        return convertedPoints
    }

        // Existing preprocessing steps
    func preprocessForPerspectiveCorrection() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        print("ciimage")

        // Find the receipt corners
        do{
            guard let corners = try findReceiptCorners(in: self) else { return nil }
            print("corners found")
            guard let correctedImage = applyPerspectiveCorrection(to: ciImage, withFeatures: corners) else { return nil }

            // Convert back to UIImage
            let context = CIContext(options: nil)
            guard let correctedCGImage = context.createCGImage(correctedImage, from: correctedImage.extent) else {
                return nil
            }

            // Convert the corner vectors back to CGPoint
            let topLeft = CGPoint(x: corners["inputTopLeft"]!.cgPointValue.x, y: corners["inputTopLeft"]!.cgPointValue.y)
            let topRight = CGPoint(x: corners["inputTopRight"]!.cgPointValue.x, y: corners["inputTopRight"]!.cgPointValue.y)
            let bottomLeft = CGPoint(x: corners["inputBottomLeft"]!.cgPointValue.x, y: corners["inputBottomLeft"]!.cgPointValue.y)
            let bottomRight = CGPoint(x: corners["inputBottomRight"]!.cgPointValue.x, y: corners["inputBottomRight"]!.cgPointValue.y)

            let newCorners = [topLeft, topRight, bottomRight, bottomLeft] // Ensure the order forms a rectangle

            // Assuming you have a function `drawRectangleOnImage(image:corners:)` that draws a rectangle on the image
            let correctedUIImage = UIImage(cgImage: correctedCGImage)
            if let imageWithRectangle = drawRectangleOnImage(image: correctedUIImage, corners: newCorners) {
                // Use `imageWithRectangle` in your UIImageView or UI component to display
                return correctedUIImage
            }
        }
        catch{
            
        }
        // Apply perspective correction
        return self
    }

    // This function converts a CIVector to a CGPoint

    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        let scaledImage = renderer.image { _ in
            draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        return scaledImage
    }
    
    func convertToGrayscale() -> UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter.outputImage, let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    func binarize(threshold: CGFloat = 0.5) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIColor(color: .white), forKey: kCIInputColorKey)
        filter?.setValue(threshold, forKey: kCIInputIntensityKey)
        guard let resultImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgResultImage = context.createCGImage(resultImage, from: resultImage.extent) else { return nil }
        
        return UIImage(cgImage: cgResultImage)
    }
}

extension UIImage {
    func drawRectangleOnImage(image: UIImage, corners: [CGPoint]) -> UIImage? {
        // Begin a graphics context
        UIGraphicsBeginImageContext(image.size)
        
        // Draw the original image as the background
        image.draw(at: CGPoint.zero)
        
        // Set up the line attributes
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(5.0)
        context?.setStrokeColor(UIColor.red.cgColor)
        
        // Create a path for the rectangle
        let rectanglePath = UIBezierPath()
        
        // Move to the first corner
        rectanglePath.move(to: corners[0])
        
        // Draw lines to the other corners
        for i in 1..<corners.count {
            rectanglePath.addLine(to: corners[i])
        }
        
        // Close the path to create a complete rectangle
        rectanglePath.close()
        
        // Draw the path
        rectanglePath.stroke()
        
        // Extract the image
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the graphics context
        UIGraphicsEndImageContext()
        
        return resultImage
    }

    func findReceiptCorners(in image: UIImage) throws -> [String: CIVector]? {
        guard let cgImage = image.cgImage else { return nil }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.2 // Lower aspect ratio for longer receipts
           request.maximumAspectRatio = 1.0 // Max aspect ratio to allow for various receipt sizes
           request.quadratureTolerance = 50 // Degrees of tolerance for rectangle skew
           request.minimumSize = 0.2 // Minimum size of the receipt as a proportion of the image
           request.minimumConfidence = 0.5 // Minimum confidence to accept a detection
           request.maximumObservations = 1 // Only the most prominent receipt is needed

        do {
            try requestHandler.perform([request])

            guard let results = request.results else {
                print("error1")
                return nil
            }
                  
            guard let observation = results.first else {
                print("error2")
                throw ReceiptError.noObservations
                return nil
            }
            print("we made it")

            let topLeft = CIVector(cgPoint: observation.topLeft.scaled(to: image.size))
            let topRight = CIVector(cgPoint: observation.topRight.scaled(to: image.size))
            let bottomLeft = CIVector(cgPoint: observation.bottomLeft.scaled(to: image.size))
            let bottomRight = CIVector(cgPoint: observation.bottomRight.scaled(to: image.size))
            print(topLeft)
            print(topRight)
            print(bottomLeft)

            print(bottomRight)

            return [
                "inputTopLeft": topLeft,
                "inputTopRight": topRight,
                "inputBottomLeft": bottomLeft,
                "inputBottomRight": bottomRight
            ]
        } catch {
            print(error)
            throw error
        }
    }
}

private extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: (1 - self.y) * size.height)
    }
}
extension CIVector {
    var cgPointValue: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
}
enum ReceiptError: Error {
    case cgImageConversionFailed
    case noResults
    case noObservations
}
