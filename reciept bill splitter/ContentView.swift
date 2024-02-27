import SwiftUI
import UIKit
import Vision

struct ContentView: View {
    @StateObject var scanReceipt = ScanReceipt()
    @State private var isCameraPresented = false
    @State private var selectedImage: UIImage?
    @State private var isTaken = false // Assuming this flag is set to true when an image is captured
   @State var uiImage: UIImage? // Assuming you have a UIImage

    var body: some View {
        VStack {
            // Your existing UI components
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
            if let uiImage = scanReceipt.uiImage {
                Image(uiImage: uiImage)
                    .resizable() // Make the image resizable
                    .aspectRatio(contentMode: .fit) // Maintain aspect ratio and fit within the view
                    .frame(width: 500, height: 500) // Set frame size (adjust as needed)
                    .border(Color.black, width: 1) // Optional: Add a border to highlight the image area
            } else {
                Text("Image not available")
            }
                  
                  if scanReceipt.isScanning {
                      ProgressView()
                          .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                          .scaleEffect(1.5)
                          .padding()
                  }
            Button("scan test") {
                Task{
                           guard let image = UIImage(named: "Test6") else {
                               print("Error loading Image")
                               return
                           }
                           await scanReceipt.scanReceipt(image: image)
                       }
            }
            Button("Open Camera") {
                isCameraPresented = true
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraView(isPresented: $isCameraPresented, selectedImage: $selectedImage, isTaken: $isTaken)
            }
            .onChange(of: isTaken) {
                    if let imageToScan = selectedImage {
                        Task {
                            await scanReceipt.scanReceipt(image: imageToScan)
                        }
                    }
                    isTaken = false // Reset the flag
                }
            }
        }
    }


    struct ImagePicker: UIViewControllerRepresentable {
        @Environment(\.presentationMode) var presentationMode
        @Binding var selectedImage: UIImage?
        
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            var parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    }

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var isTaken: Bool // Add this line to include the isTaken binding
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.isTaken = true // Set isTaken to true when an image is captured
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

