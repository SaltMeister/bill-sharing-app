import UIKit
import Vision

struct ReceiptItem: Identifiable {
    let id: UUID
    var name: String
    var price: Double
}

struct TextElement: Equatable {
    var text: String
    var frame: CGRect
    var price: Double?
}
extension CGRect {
    // Add a computed property to CGRect to easily get the center point
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }

    // Add a method to scale CGRect
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(x: self.origin.x * size.width,
                      y: self.origin.y * size.height,
                      width: self.width * size.width,
                      height: self.height * size.height)
    }
}
class ScanReceipt: ObservableObject {
    @Published  var receiptItems: [ReceiptItem] = []
    @Published  var total: ReceiptItem?
    @Published  var tax: ReceiptItem?
    @Published  var isScanning = false
    private var finalTax: ReceiptItem?
    private var finalTotal: ReceiptItem?
    private var finalItems: [ReceiptItem] = []
    private var receiptItemsTemp: [ReceiptItem] = []
    @Published var uiImage: UIImage?
    private var tempimage: UIImage?
    func scanReceipt(image: UIImage) async {
        Task { @MainActor in
            self.isScanning = true
            self.receiptItems = []
            self.total = nil
            self.tax = nil
            finalTax = nil
            finalTotal = nil
            finalItems = []
            receiptItemsTemp = []
            uiImage = nil
        }
        print("here")
        await runModel(image: image)
        
        Task { @MainActor in
            self.tax = finalTax
            self.receiptItems = finalItems
            self.total = finalTotal
            self.isScanning = false
            self.uiImage = tempimage
        }
    }
    
    private func runModel(image: UIImage) async {
        // Step 1: Detect receipt corners and correct perspective
        print("run")
        // Step 2: Apply additional preprocessing like scaling and binarization if needed
        guard let preprocessedImage = preprocessImage(image) else { return }
        print("processed image")
        guard let correctedImage = preprocessedImage.preprocessForPerspectiveCorrection() else { return }
        print("corrected image")
        tempimage = correctedImage
        guard let cgImage = correctedImage.cgImage else { return }
        // Step 3: Prepare and perform the text recognition request
        let request = createTextRecognitionRequest(with: correctedImage.size)
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform text recognition request: \(error)")
        }
    }
    private func createTextRecognitionRequest(with originalImageSize: CGSize) -> VNRecognizeTextRequest {
        let textRequest = VNRecognizeTextRequest { (request, error) in
            if let results = request.results as? [VNRecognizedTextObservation] {
                self.splitPricesAndItems2(results, in: originalImageSize)
            }
        }
        textRequest.recognitionLevel = .accurate // Use accurate recognition level
        textRequest.usesLanguageCorrection = true
        return textRequest
    }
 

    private func splitPricesAndItems2(_ observations: [VNRecognizedTextObservation], in imageSize: CGSize) {
        var receiptItems: [ReceiptItem] = []

        for observation in observations {
            guard let recognizedText = observation.topCandidates(1).first else { continue }
            let text = recognizedText.string
            print(text)
            // Check if the text represents a price
            if isPriceLine(text) {
                print(text)
                let priceFrame = convertFromNormalizedRect(observation.boundingBox, imageSize: imageSize)
                let lineHeight = priceFrame.height * 0.5 // Use the price's bounding box height as the line height
                
                // Find items to the left of the price within the same line height
                var lineItems: [String] = []
                for otherObservation in observations {
                    guard let otherText = otherObservation.topCandidates(1).first?.string,
                          otherObservation != observation else { continue }
                    
                    let otherFrame = convertFromNormalizedRect(otherObservation.boundingBox, imageSize: imageSize)
                    
                    // Check if otherText is on the same line as the price
                    if abs(otherFrame.midY - priceFrame.midY) < lineHeight {
                        // Check if otherText is to the left of the price
                        if otherFrame.maxX <= priceFrame.minX {
                            lineItems.append(otherText)
                        }
                    }
                }
                
                let itemName = lineItems.joined(separator: " ")
                if let price = extractPrice(from: text) {
                    let receiptItem = ReceiptItem(id: UUID(), name: itemName, price: price)
                    receiptItems.append(receiptItem)
                }
            }
        }
        for item in receiptItems {
            print("Item: \(item.name), Price: \(item.price)")
        }
        extractTaxAndTotal(from: receiptItems)
    }

    func removePaymentMethods(from items: [ReceiptItem]) -> [ReceiptItem] {
        let paymentKeywords = ["credit", "debit", "cash", "card", "change", "visa", "amex", "mastercard", "discover", "american express", "subtotal"]
        return items.filter { item in
            !paymentKeywords.contains(where: { keyword in
                item.name.lowercased().contains(keyword)
            })
        }
    }
    
    func extractTaxAndTotal(from items: [ReceiptItem]){
        let taxItems = items.filter { isTaxLine($0.name) }
        let itemsWithoutTax = items.filter { !isTaxLine($0.name) }
        self.finalTax = extractTax(taxItems)
        
        self.receiptItemsTemp = itemsWithoutTax
        self.receiptItemsTemp = removePaymentMethods(from: self.receiptItemsTemp)
        (finalItems, finalTotal) = extractTotal(self.receiptItemsTemp)
    }
    func isPriceLine2(_ text: String) -> Bool {
        // Regular expression pattern to match strictly price lines
        // This includes an optional dollar sign, followed by digits, a decimal point, and two digits
        // It may also allow for a single trailing character which could be an artifact from OCR
        let pattern = "^\\$?[0-9]+\\.\\s?[0-9]{2}[A-Za-z]?$"

        // Attempt to create a regular expression object with the pattern
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }

        // Define the range of the text to check
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        // Search for the first match of the pattern within the text
        let match = regex.firstMatch(in: text, options: [], range: range)

        // If a match is found and it covers the entire range of the text, it's considered a price line
        return match != nil && match?.range == range
    }

    func extractTax(_ taxItems: [ReceiptItem]) -> ReceiptItem? {
        let totalTaxAmount = taxItems.reduce(0) { $0 + $1.price }
        return taxItems.isEmpty ? nil : ReceiptItem(id: UUID(), name: "Total Tax", price: totalTaxAmount)
    }
    
    func extractTotal(_ items: [ReceiptItem]) -> (items: [ReceiptItem], finalTotal: ReceiptItem?) {
        var finalItems = [ReceiptItem]()
        var potentialTotals = [ReceiptItem]()
        for item in items {
            if isTotalLine(item.name) {
                potentialTotals.append(item)
            } else {
                finalItems.append(item)
            }
        }
        let finalTotal = potentialTotals.max(by: { $0.price < $1.price })
        if let finalTotal = finalTotal, let index = finalItems.firstIndex(where: { $0.id == finalTotal.id }) {
            finalItems.remove(at: index)
        }
        return (finalItems, finalTotal)
    }
    
    func extractPrice(from text: String) -> Double? {
        let pattern = "\\$?[0-9]+\\.\\s?[0-9]{1,2}[A-Za-z]?"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let matchedString = (text as NSString).substring(with: match.range)
            let filteredPriceText = matchedString.filter { "0123456789.".contains($0) }
            return Double(filteredPriceText)
        }
        return nil
    }
    
    func isTotalLine(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return !lowercasedText.contains("sub") && (lowercasedText.contains("total") || lowercasedText.contains("balance") || lowercasedText.contains("amount"))
    }
    
    func isTaxLine(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return lowercasedText.contains("tax")
    }
    
    private func isPriceLine(_ text: String) -> Bool {
        let pattern = "\\$?[0-9]+\\.\\s?[0-9]{1,2}[A-Za-z]?"
        let regex = try? NSRegularExpression(pattern: pattern)
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex?.firstMatch(in: text, options: [], range: range) != nil && !text.contains("%")
    }
    
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        let targetSize = CGSize(width: 720, height: 1280) // Adjust based on your needs
        let scaledImage = image.scalePreservingAspectRatio(targetSize: targetSize)
        guard let binaryImage = scaledImage.convertToGrayscale()?.binarize() else { return nil }
       return binaryImage
    }

    private func convertFromNormalizedRect(_ normalizedRect: CGRect, imageSize: CGSize) -> CGRect {
        return CGRect(x: normalizedRect.minX * imageSize.width,
                      y: (1 - normalizedRect.maxY) * imageSize.height,
                      width: normalizedRect.width * imageSize.width,
                      height: normalizedRect.height * imageSize.height)
    }

}

class ReceiptDetector {
    
    func detectReceipt(in image: UIImage, completion: @escaping (VNRectangleObservation?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectRectanglesRequest { request, error in
            guard error == nil else {
                print("Rectangle detection error: \(String(describing: error))")
                completion(nil)
                return
            }
            
            // Assuming the receipt is the largest rectangle found
            let receiptObservation = request.results?.first as? VNRectangleObservation
            completion(receiptObservation)
        }
        
        // Configure the request
        request.minimumConfidence = 0.8 // Adjust based on your needs
        request.maximumObservations = 1 // Assuming only one receipt is present
        request.minimumAspectRatio = 0.3 // Adjust to match the expected aspect ratio of a receipt
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform rectangle detection: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
}
