import SwiftUI
import UIKit
import MLKitTextRecognition
import MLKitVision
import CoreGraphics
import CoreImage

struct ContentView: View {
    @StateObject var scanReceipt = ScanReceipt()  // Holds the instance of ScanReceipt
    @State private var isScanning = false  // Tracks whether scanning is in progress
    @State var turboMode: Bool = false      // To show scanning is running in background
    
    var body: some View {
        VStack {
            Text("Receipt Items")
            List(scanReceipt.receiptItems) { item in  // Directly use scanReceipt.receiptItems here
                Text("\(item.name): $\(item.price, specifier: "%.2f")")
            }
            
            if let tax = scanReceipt.tax {  // Directly use scanReceipt.tax here
                Text("Tax: \(tax.name): $\(tax.price, specifier: "%.2f")")
                    .foregroundColor(.red)
            }
            if let total = scanReceipt.total {  // Directly use scanReceipt.total here
                Text("Total: $\(total.price, specifier: "%.2f")")
                    .foregroundColor(.red)
            }
         
            Toggle("Turbo mode", isOn: $turboMode)

            // Progress view that appears while scanning
            if scanReceipt.isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                    .padding()
            }

            Button("Scan Receipt") {
                guard let image = UIImage(named: "Test6") else {
                    print("Error loading Image")
                    return
                }
                
                scanReceipt.scanReceipt(image: image)

            }
        }
    }
}
