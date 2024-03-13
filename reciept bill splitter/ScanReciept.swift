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
    @Published  var discount: ReceiptItem?
    @Published  var isScanning = false
    @Published var title: String?
    private var finalTax: ReceiptItem?
    private var finalTotal: ReceiptItem?
    private var finalDiscount: ReceiptItem?
    private var titleTemp: String?
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
            finalDiscount = nil
            finalItems = []
            receiptItemsTemp = []
            uiImage = nil
            titleTemp = nil
        }
        print("here")
        await runModel(image: image)
        
        Task { @MainActor in
            self.discount = finalDiscount
            self.tax = finalTax
            if let tax = finalTax {
                finalItems.append(tax)
            }
            self.receiptItems = finalItems
            self.total = finalTotal
            self.isScanning = false
            self.uiImage = tempimage
            self.title = titleTemp
            
        }
    }
    
    private func runModel(image: UIImage) async {
        // Step 1: Detect receipt corners and correct perspective (skipping in this version)
        print("run")

        // Step 2: Apply additional preprocessing like scaling and binarization if needed
        guard let preprocessedImage = preprocessImage(image) else { return }
        print("processed image")

        // Skipping the perspective correction step
        // Using 'preprocessedImage' directly for text recognition
        tempimage = preprocessedImage

        guard let cgImage = preprocessedImage.cgImage else { return }

        // Step 3: Prepare and perform the text recognition request using the preprocessed image
        let request = createTextRecognitionRequest(with: preprocessedImage.size)
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
        var priceMaxXValues: [CGFloat] = []
        var priceWidths: [CGFloat] = []
        var potentialTitleObservations: [VNRecognizedTextObservation] = []

        // Collect potential title observations and price information
        for observation in observations.prefix(5) {
            guard let recognizedText = observation.topCandidates(1).first else { continue }
            print(recognizedText.string)
            if !isPriceLine(recognizedText.string) {
                potentialTitleObservations.append(observation)
            }
        }
        
        for observation in observations {
            guard let recognizedText = observation.topCandidates(1).first, let priceFrame = isPriceLine(recognizedText.string) ? convertFromNormalizedRect(observation.boundingBox, imageSize: imageSize) : nil else { continue }
            priceMaxXValues.append(priceFrame.maxX)
            priceWidths.append(priceFrame.width)
        }

        // Identify potential title based on height
        let titleObservation = potentialTitleObservations.max(by: { convertFromNormalizedRect($0.boundingBox, imageSize: imageSize).height < convertFromNormalizedRect($1.boundingBox, imageSize: imageSize).height })

        // Calculate average height excluding the title observation
        let nonTitleObservations = potentialTitleObservations.filter { $0 != titleObservation }
        let averageHeight = nonTitleObservations.map { convertFromNormalizedRect($0.boundingBox, imageSize: imageSize).height }.reduce(0, +) / CGFloat(nonTitleObservations.count)

        // Validate and set title
        if let titleObservation = titleObservation, convertFromNormalizedRect(titleObservation.boundingBox, imageSize: imageSize).height >= 2 * averageHeight {
            titleTemp = titleObservation.topCandidates(1).first?.string
        }


        // Find the maximum maxX value and calculate the average width
        let maxMaxX = priceMaxXValues.max() ?? 0
        let averageWidth = priceWidths.reduce(0, +) / CGFloat(priceWidths.count)

        // Adjust the maximum maxX by subtracting the average width to set a threshold
        let thresholdMaxX = maxMaxX - (averageWidth)

        for observation in observations {
            guard let recognizedText = observation.topCandidates(1).first else { continue }
            let text = recognizedText.string
            print(text)
            
            // Check if the text represents a price
            if isPriceLine(text) {
                let priceFrame = convertFromNormalizedRect(observation.boundingBox, imageSize: imageSize)
                
                // Skip prices to the left of the threshold
                if priceFrame.maxX < thresholdMaxX {
                    continue
                }

                let lineHeight = priceFrame.height * 0.4 // Adjust the line height if necessary

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
        let discountItems = itemsWithoutTax.filter { $0.price < 0 }
        let itemsWithoutDiscountItems = itemsWithoutTax.filter { $0.price > 0 }
        self.finalDiscount = calculateTotalDiscounts(from: discountItems)
        self.finalTax = extractTax(taxItems)
        
        self.finalDiscount = calculateTotalDiscounts(from: discountItems)
        self.receiptItemsTemp = itemsWithoutDiscountItems
        self.receiptItemsTemp = removePaymentMethods(from: self.receiptItemsTemp)
        (finalItems, finalTotal) = extractTotal(self.receiptItemsTemp)
    }

    func extractTax(_ taxItems: [ReceiptItem]) -> ReceiptItem? {
        let totalTaxAmount = taxItems.reduce(0) { $0 + $1.price }
        return taxItems.isEmpty ? nil : ReceiptItem(id: UUID(), name: "Total Tax", price: totalTaxAmount)
    }
    func calculateTotalDiscounts(from items: [ReceiptItem]) -> ReceiptItem? {
        // Filter out negative prices and sum them up
        let totalDiscount = items.reduce(0) { $0 + $1.price }
        return items.isEmpty ? nil : ReceiptItem(id: UUID(), name: "Total Discounts", price: totalDiscount)
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
        // Include an optional minus sign either at the start or the end of the pattern
        let pattern = "-?\\$?\\s?[0-9]+(\\.\\s?[0-9]{1,2})?\\s?-?"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            var matchedString = (text as NSString).substring(with: match.range)
            
            // Check if the minus sign is at the end and move it to the start
            if matchedString.hasSuffix("-") {
                matchedString.removeLast() // Remove the trailing minus
                matchedString.insert("-", at: matchedString.startIndex) // Insert it at the start
            }
            
            // Ensure the matched string is filtered correctly to remove any non-numeric characters except the minus sign
            let filteredPriceText = matchedString.filter { "-0123456789.".contains($0) }
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
