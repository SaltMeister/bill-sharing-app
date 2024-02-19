
import SwiftUI
import UIKit
import CoreGraphics
import CoreImage

// UIImage extension for resizing and binarization
extension UIImage {
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
    }}
func preprocessImage(_ originalImage: UIImage) -> UIImage? {
    // Resize the image while maintaining its aspect ratio
    let targetSize = CGSize(width: 720, height: 1280) // Adjust based on your needs
    let scaledImage = originalImage.scalePreservingAspectRatio(targetSize: targetSize)
    
    // Apply binarization - This is a simplified example, you might need a more complex approach
    guard let binaryImage = scaledImage.convertToGrayscale()?.binarize() else { return nil }
    
    return binaryImage
}
func preprocessImageForMLKit(_ originalImage: UIImage, targetSize: CGSize) -> UIImage? {
    // Resize image
    guard let resizedImage = resizeImage(originalImage, targetSize: targetSize) else { return nil }

    // Convert to grayscale
    let context = CIContext()
    guard let filter = CIFilter(name: "CIPhotoEffectNoir", parameters: [kCIInputImageKey: CIImage(image: resizedImage)!]),
          let output = filter.outputImage,
          let cgImage = context.createCGImage(output, from: output.extent) else {
        return resizedImage // Return the resized image if grayscale conversion fails
    }
    
    let grayscaleImage = UIImage(cgImage: cgImage)

    // Apply binarization
    return binarizeImage(grayscaleImage)
}

func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size

    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    // Determine the scale factor that preserves aspect ratio
    let scaleFactor = min(widthRatio, heightRatio)

    let scaledImageSize = CGSize(
        width: size.width * scaleFactor,
        height: size.height * scaleFactor
    )

    let renderer = UIGraphicsImageRenderer(size: scaledImageSize)

    let scaledImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: scaledImageSize))
    }

    return scaledImage
}

func binarizeImage(_ image: UIImage) -> UIImage? {
    guard let ciImage = CIImage(image: image),
          let filter = CIFilter(name: "CIColorMonochrome") else { return nil }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(CIColor(color: .black), forKey: kCIInputColorKey)
    filter.setValue(1.0, forKey: kCIInputIntensityKey)

    let context = CIContext()
    guard let outputImage = filter.outputImage,
          let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }

    return UIImage(cgImage: cgImage)
}
//
//  UIImageExtension.swift
//  reciept bill splitter
//
//  Created by Diego Martinez on 19/02/24.
//

import Foundation
