//
//  HomeView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct HomeView: View {
    @StateObject var scanReceipt = ScanReceipt()
    @State private var isCameraPresented = false
    @State private var selectedImage: UIImage?
    @State private var isTaken = false // Assuming this flag is set to true when an image is captured
   @State var uiImage: UIImage? // Assuming you have a UIImage

    var body: some View {
        VStack {
            // Your existing UI components
            if let title = scanReceipt.title {
                HStack {
                    Text(title)
                        .font(.headline) // Make the amount stand out
                        .foregroundColor(.green) // Consistent color for discounts
                }
                .padding() // Add some padding for better spacing
            }
            List(scanReceipt.receiptItems) { item in
                HStack {
                    Text(item.name)
                        .font(.body) // Customize the font as needed
                        .foregroundColor(.primary) // Adjust the text color
                        .padding(.leading, 10) // Add some padding for better alignment

                    Spacer() // This pushes the name and price to opposite sides of the HStack

                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.headline) // Customize the font as needed
                        .foregroundColor(.secondary) // Adjust the text color for the price
                        .padding(.trailing, 10) // Add some padding for better alignment
                }
                .padding(.vertical, 5) // Add vertical padding to each list item for better spacing
            }
            .listStyle(PlainListStyle()) // Use a list style that suits your needs

            // For Discounts
            if let discount = scanReceipt.discount {
                HStack {
                    Text("Discounts:")
                        .font(.headline) // Make the label stand out
                        .foregroundColor(.green) // Use green to indicate savings
                    Spacer() // Pushes the text to the left and the amount to the right
                    Text("$\(discount.price, specifier: "%.2f")")
                        .font(.headline) // Make the amount stand out
                        .foregroundColor(.green) // Consistent color for discounts
                }
                .padding() // Add some padding for better spacing
            }

            // For Tax
            if let tax = scanReceipt.tax {
                HStack {
                    Text("Tax:")
                        .font(.headline) // Make the label stand out
                        .foregroundColor(.red) // Red can indicate an additional charge
                    Spacer()
                    Text("$\(tax.price, specifier: "%.2f")")
                        .font(.headline) // Make the amount stand out
                        .foregroundColor(.red) // Consistent color for tax
                }
                .padding() // Add some padding for better spacing
            }

            // For Total
            if let total = scanReceipt.total {
                HStack {
                    Text("Total:")
                        .font(.headline) // Make the label stand out
                        .foregroundColor(.blue) // Blue for the final total
                    Spacer()
                    Text("$\(total.price, specifier: "%.2f")")
                        .font(.headline) // Make the amount stand out
                        .foregroundColor(.blue) // Consistent color for the total
                }
                .padding() // Add some padding for better spacing
            }
                  
                  if scanReceipt.isScanning {
                      ProgressView()
                          .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                          .scaleEffect(1.5)
                          .padding()
                  }
          
            Button("Create Transaction") {
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



struct BottomToolbar: View {
    var body: some View {
        NavigationStack{
            HStack(spacing: 0.2) {
                ToolbarItem(iconName: "person.2", text: "Friends", destination: AnyView(FriendsView()))
                ToolbarItem(iconName: "person.3", text: "Groups", destination: AnyView(GroupView()))
                ToolbarItem(iconName: "bolt", text: "Activities", destination: AnyView(HistoryView()))
                ToolbarItem(iconName: "person.crop.circle", text: "Accounts", destination: AnyView(AccountView()))
            }
            .frame(height: 50)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 3)
        }
    }
}

struct ToolbarItem: View {
    let iconName: String
    let text: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                Text(text)
                    .font(.caption)
            }
            .padding(.horizontal, 20)
        }
    }
}
