//
//  GroupDetailView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 3/15/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct GroupDetailView: View {
    @State private var isCameraPresented = false
    @State private var selectedImage: UIImage?
    @State private var isTaken = false
    @State private var existingTransactions: [Transaction] = []
    @State private var totalSpent: Double = 0
    
    let group: Group
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        VStack {
            Text("Group: \(group.group_name)")
                .font(.title)
                .padding()
            
            // Display list of transactions for the group
            if !existingTransactions.isEmpty {
                List(existingTransactions, id: \.transaction_id) { transaction in
                    NavigationLink(destination: TransactionView()) {
                                        Text(transaction.name)
                                            .onTapGesture {
                                                user.selectedTransaction = transaction
                                            }
                                    }
                }
            } else {
                Text("No transactions found")
            }
            
            // Button to take a picture of a receipt
            Button(action: {
                isCameraPresented = true
            }) {
                Text("Take Picture of Receipt")
            }
            .sheet(isPresented: $isCameraPresented) {
                // Present CameraView when the button is tapped
                CameraView(isPresented: $isCameraPresented, selectedImage: $selectedImage, isTaken: $isTaken)
            }
        }
        .navigationTitle("Group Details")
        .onAppear {
            // Load transactions for the group
            Task {
                existingTransactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: group.groupID) ?? []
                totalSpent = existingTransactions.reduce(0) { $0 + Double($1.itemList.reduce(0) { $0 + $1.priceInCents }) / 100 }
            }
        }
    }
}

