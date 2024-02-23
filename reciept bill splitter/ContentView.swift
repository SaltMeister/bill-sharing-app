import SwiftUI
import UIKit
import Vision


struct ContentView: View {
    @StateObject var scanReceipt = ScanReceipt()
    @State private var isScanning = false
    @State var turboMode: Bool = false
    @State private var extractedEntities: [String] = []

    var body: some View {
        VStack {
            Text("Receipt Items")
            List(scanReceipt.receiptItems) { item in
                Text("\(item.name): $\(item.price, specifier: "%.2f")")
            }
        
            if let tax = scanReceipt.tax {
                Text("Tax: $\(tax.price, specifier: "%.2f")")
                    .foregroundColor(.red)
            }
            
            if let total = scanReceipt.total {
                Text("Total: $\(total.price, specifier: "%.2f")")
                    .foregroundColor(.red)
            }
            
            Toggle("Turbo mode", isOn: $turboMode)
            
            if scanReceipt.isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                    .padding()
            }

            Button("Scan Receipt") {
                Task{
                    guard let image = UIImage(named: "Test6") else {
                        print("Error loading Image")
                        return
                    }
                    await scanReceipt.scanReceipt(image: image)
                }
            }
        }
    }
}
