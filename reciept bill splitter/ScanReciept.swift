import SwiftUI
import UIKit
import MLKitTextRecognition
import MLKitVision
import CoreGraphics
import CoreImage

struct TextElement: Equatable {
    var text: String
    var frame: CGRect
    var price: Double?  // Optional price if present on the same line
}

struct ReceiptItem: Identifiable {
    let id: UUID
    var name: String
    var price: Double
}

class ScanReceipt: ObservableObject {
    @Published var receiptItems: [ReceiptItem] = []
    @Published var total: ReceiptItem?
    @Published var tax: ReceiptItem?
    @Published var isScanning = false  // Track scanning state

    var receiptItemsTemp: [ReceiptItem] = []

    func scanReceipt(image: UIImage)  {
        DispatchQueue.main.async {
            self.tax = nil
            self.receiptItems = []
            self.total = nil
            self.isScanning = true
        }
        
      
        let latinOptions = TextRecognizerOptions()
        let textRecognizer = TextRecognizer.textRecognizer(options: latinOptions)
        DispatchQueue.global(qos: .userInitiated).async {
            guard let preprocessedImage = self.preprocessImage(image) else {
                return
            }
            let visionImage = VisionImage(image: preprocessedImage)
            textRecognizer.process(visionImage) { result, error in
                guard let result = result, error == nil else {
                    return
                }
                self.processTextRecognitionResult(result)
            }
        }
   
        
    }
    
    private func processTextRecognitionResult(_ result: MLKitTextRecognition.Text) {
        var items = [TextElement]()  // Items found in the receipt
        var prices = [TextElement]() // Prices found in the receipt
        
        result.blocks.forEach { block in
            block.lines.forEach { line in
                let lineText = line.text.lowercased()
                let lineFrame = line.frame
                if self.isPriceLine(lineText) {
                    prices.append(TextElement(text: lineText, frame: lineFrame))
                } else {
                    items.append(TextElement(text: lineText, frame: lineFrame))
                }
            }
        }
        
        self.associatePricesWithItems(items: items, prices: prices)
    }
    
    private func associatePricesWithItems(items: [TextElement], prices: [TextElement]) {
        // Logic to associate prices with items here...
      
        var associatedItems: [ReceiptItem] = []
        var availableItems = items // Copy of items to keep track of unpaired items
        var availablePrices = prices // Copy of prices to keep track of unpaired prices
        
        for price in prices {
            var closestItem: TextElement?
            var minDistance = CGFloat.greatestFiniteMagnitude
            
            for item in availableItems {
                let distance = abs(price.frame.minX - item.frame.maxX)
                
                // Ensure the item is to the left and within the same line or a nearby line
                if distance < minDistance && abs(price.frame.midY - item.frame.midY) < 50 { // Adjust the value as needed
                    closestItem = item
                    minDistance = distance
                }
            }
            
            if let item = closestItem, let priceIndex = availablePrices.firstIndex(of: price), let itemIndex = availableItems.firstIndex(of: item) {
                // Remove all non-numeric characters except the decimal point from the price text
                let filteredPriceText = price.text.filter { "0123456789.".contains($0) }
                if let priceValue = Double(filteredPriceText) {
                    // Create a new ReceiptItem with a unique ID for each item
                    let receiptItem = ReceiptItem(id: UUID(), name: item.text, price: priceValue)
                    associatedItems.append(receiptItem)
                    
                    // Remove the paired item and price from the available lists
                    availablePrices.remove(at: priceIndex)
                    availableItems.remove(at: itemIndex)
                }
            }
        }
        
        // After processing, call completion
        receiptItemsTemp = associatedItems
        extractItems(from: self.receiptItemsTemp)
    }
    
    // Implement the rest of your utility methods here...
    
    private func isPriceLine(_ text: String) -> Bool {
        let pattern = "\\$[0-9]+(\\.[0-9]{2})?[A-Za-z]?"
        let regex = try? NSRegularExpression(pattern: pattern)
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex?.firstMatch(in: text, options: [], range: range) != nil
    }
    
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        // Your image preprocessing logic here...
        let targetSize = CGSize(width: 720, height: 1280) // Adjust based on your needs
        let scaledImage = image.scalePreservingAspectRatio(targetSize: targetSize)
        
        // Apply binarization - This is a simplified example, you might need a more complex approach
        guard let binaryImage = scaledImage.convertToGrayscale()?.binarize() else { return nil }
        
        return binaryImage
    }
    
    // Additional methods for tax processing, filtering out payment methods, etc.
    func filterOutPaymentMethods(from items: [ReceiptItem]) -> [ReceiptItem] {
        let paymentKeywords = ["credit", "debit", "cash", "card", "change", "visa", "amex", "mastercard", "discover"]
        return items.filter { item in
            !paymentKeywords.contains(where: { keyword in
                item.name.lowercased().contains(keyword)
            })
        }
    }
    
    
    func isTaxLine(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return lowercasedText.contains("tax")
    }
    func extractItems(from items: [ReceiptItem]){
        let taxItems = items.filter { isTaxLine($0.name) }
        let itemsWithoutTax = items.filter { !isTaxLine($0.name) }
        let finalTax = finalizeTaxItems(taxItems)
        
        self.receiptItemsTemp = itemsWithoutTax
        self.receiptItemsTemp = filterOutPaymentMethods(from: self.receiptItemsTemp)
        let (finalItems, finalTotal) = finalizeReceiptItems(self.receiptItemsTemp)
        
        DispatchQueue.main.async {
            // Logic to associate prices with items and update @Published properties...
            self.tax = finalTax
            self.receiptItems = finalItems
            self.total = finalTotal
            self.isScanning = false
        }

        
    }
    func finalizeTaxItems(_ taxItems: [ReceiptItem]) -> ReceiptItem? {
        let totalTaxAmount = taxItems.reduce(0) { $0 + $1.price }
        return taxItems.isEmpty ? nil : ReceiptItem(id: UUID(), name: "Total Tax", price: totalTaxAmount)
        
        // If you only want to take the highest tax line (uncomment if needed):
        // return taxItems.max(by: { $0.price < $1.price })
    }
    
    
    
    func finalizeReceiptItems(_ items: [ReceiptItem]) -> (items: [ReceiptItem], finalTotal: ReceiptItem?) {
        var finalItems = [ReceiptItem]()
        var potentialTotals = [ReceiptItem]()
        // Separate potential total/balance lines from regular item lines
        for item in items {
            if isTotalLine(item.name) {
                potentialTotals.append(item)
            } else {
                finalItems.append(item)
            }
        }
        // Determine the highest total from potential totals
        let finalTotal = potentialTotals.max(by: { $0.price < $1.price })
        
        // Remove the final total from the list of items if it's among them
        if let finalTotal = finalTotal, let index = finalItems.firstIndex(where: { $0.id == finalTotal.id }) {
            finalItems.remove(at: index)
        }
        
        return (finalItems, finalTotal)
    }
    func isTotalLine(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return lowercasedText.contains("total") || lowercasedText.contains("balance")
    }
    func extractPrice(from text: String) -> Double? {
        let pattern = "\\$[0-9]+(\\.[0-9]{2})?[A-Za-z]?" // Regular expression pattern for price
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let matchedString = (text as NSString).substring(with: match.range)
            let filteredPriceText = matchedString.filter { "0123456789.".contains($0) }
            return Double(filteredPriceText)
        }
        return nil
    }
    
}

