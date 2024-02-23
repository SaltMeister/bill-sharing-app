import SwiftUI
import UIKit
import Vision

struct TextElement: Equatable {
    var text: String
    var frame: CGRect
    var price: Double?
}

struct ReceiptItem: Identifiable {
    let id: UUID
    var name: String
    var price: Double
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
        
    func scanReceipt(image: UIImage) async {
        Task { @MainActor in
            self.isScanning = true
            self.receiptItems = []
            self.total = nil
            self.tax = nil
        }
        
        await runModel(image: image)
        
        Task { @MainActor in
            self.tax = finalTax
            self.receiptItems = finalItems
            self.total = finalTotal
            self.isScanning = false
        }
    }
    
    private func runModel(image: UIImage) async {
        guard let preprocessedImage = preprocessImage(image), let cgImage = preprocessedImage.cgImage else { return }
        let request = createTextRecognitionRequest(with: image.size)
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
                self.splitPricesAndItems(results, in: originalImageSize)
            }
        }
        textRequest.usesLanguageCorrection = true
        return textRequest
    }

    private func splitPricesAndItems(_ observations: [VNRecognizedTextObservation], in imageSize: CGSize) {
        var items = [TextElement]()
        var prices = [TextElement]()

        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string
            let frame = self.convertFromNormalizedRect(observation.boundingBox, imageSize: imageSize)
            print(text)
            if (isPriceLine(text)) {
                prices.append(TextElement(text: text, frame: frame, price: nil))
                print("price")
            } else {
                items.append(TextElement(text: text, frame: frame, price: nil))
                print("item")
            }
        }
        associatePricesWithItems(items: items, prices: prices)
    }

    private func associatePricesWithItems(items: [TextElement], prices: [TextElement]) {
        var associatedItems: [ReceiptItem] = []

        var unmatchedPrices = prices

        for price in prices {
            var itemsToLeft: [(item: TextElement, distance: CGFloat)] = []
            for item in items {
                let distance = price.frame.minX - item.frame.maxX

                if distance > 0 && abs(price.frame.midY - item.frame.midY) < 60 {
                    itemsToLeft.append((item, distance))
                }
            }

            itemsToLeft.sort(by: { $0.distance > $1.distance })

            let fullItemName = itemsToLeft.map { $0.item.text }.joined(separator: " ")
            
            if !itemsToLeft.isEmpty, let priceValue = Double(price.text.filter("0123456789.".contains)) {
                let receiptItem = ReceiptItem(id: UUID(), name: fullItemName, price: priceValue)
                associatedItems.append(receiptItem)

                unmatchedPrices.removeAll { $0 == price }
            }
        }

        receiptItemsTemp = associatedItems
        extractTaxAndTotal(from: self.receiptItemsTemp)
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
        return !lowercasedText.contains("sub") && (lowercasedText.contains("total") || lowercasedText.contains("balance"))
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

