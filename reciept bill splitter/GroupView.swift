//
//  GroupView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct GroupView: View {
    let db = Firestore.firestore()
    
    @State private var isCameraPresented = false
    @State private var selectedImage: UIImage?
    @State private var isTaken = false
    
    @State var selectedGroup: Group?
    @State var existingTransactions: [Transaction] = []
    @State private var totalSpent: [Double] = []
    
    @StateObject var scanReceipt = ScanReceipt()
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        NavigationStack{
            VStack {
                Text(selectedGroup?.group_name ?? "None")
                
                if !existingTransactions.isEmpty {
                    List {
                        ForEach(existingTransactions.indices, id: \.self) { index in
                            NavigationLink(destination: TransactionView(transaction: existingTransactions[index])) {
                                Text(existingTransactions[index].name)
                                Text("Total Spent: $\(String(format: "%.2f", totalSpent[index]))")
                            }
                        }
                    }
                } else {
                    Text("No transactions found")
                }
                
                if selectedGroup?.owner_id == user.user_id {
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
                
                Spacer()
            }
            .onChange(of: scanReceipt.isScanning) {
                if !scanReceipt.isScanning {
                    Task {
                        await createTransaction()
                    }
                }
            }
            .onAppear {
                print("DISPLAYING GROUP \(user.groups[user.selectedGroupIndex])")
                selectedGroup = user.groups[user.selectedGroupIndex]
                Task {
                    await loadTransactions()
                    listenToDocuments()
                }
            }
        }
    }
    
    private func listenToDocuments() {
        print("LISTENING TO DOCUMENTS")
        db.collection("transactions").whereField("group_id", isEqualTo: selectedGroup?.groupID ?? "")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshots = querySnapshot else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                
                if let error = error {
                    print("Error retreiving collection: \(error)")
                }
                
                
                print("Changes Made to a transaction !!!!!!")
                
                // Find Changes where document is a diff
                snapshots.documentChanges.forEach { diff in
                    if diff.type == .modified {
                        // Check if the proper field is adjusted
                        print("GROUP TRANSACTION HAS BEEN MODIFIED")
                    }
                    else if diff.type == .added {
                        print("NEW TRANSACTION CREATED FOR GROUP")
                    }
                    
                }
            }
    }
    private func createTransaction() async {
        let scannedItems = scanReceipt.receiptItems // Assume these are the scanned receipt items
        let transactionItems = scannedItems.map { Item(priceInCents: Int($0.price * 100), name: $0.name) }
        let newTransaction = Transaction(itemList: transactionItems, itemBidders: [:], name: "New Transaction from Receipt")
        await DatabaseAPI.createTransaction(transactionData: newTransaction, groupID: selectedGroup?.groupID)
    }
    
    private func loadTransactions() async {
        print("Loading transactions for group ID: \(selectedGroup?.groupID ?? "Unknown")")
        
        if let transactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup?.groupID) {
            existingTransactions = transactions // Store all transactions
            totalSpent = transactions.map { transaction in
                transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
            }
        } else {
            print("No transactions found for group \(selectedGroup?.groupID ?? "")")
        }
    }
}

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        GroupView().environmentObject(UserViewModel())
    }
}

