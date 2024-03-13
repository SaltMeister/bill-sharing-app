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
    
    @State var isViewingTransaction = false
    @State var isAlert = false
    
    @StateObject var scanReceipt = ScanReceipt()
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        NavigationStack{
            
            VStack {
                Text(selectedGroup?.group_name ?? "None")
                
                if !user.currentSelectedGroupTransactions.isEmpty {
                    List {
                        ForEach(user.currentSelectedGroupTransactions.indices, id: \.self) { index in
                            HStack {
                                Text(user.currentSelectedGroupTransactions[index].name)
                                //Text("Total Spent: $\(String(format: "%.2f", totalSpent[index]))")

                            }
                            .onTapGesture {
                                print(user.currentSelectedGroupTransactions, index)
                                user.selectedTransaction = user.currentSelectedGroupTransactions[index]
                                isViewingTransaction = true
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
            .alert(isPresented: $isAlert) {
                Alert(title: Text("ALERT"), message: Text("You have been assigned a transaction"), dismissButton: .cancel())
            }
            .navigationDestination(isPresented: $isViewingTransaction) {
                TransactionView()
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
                
                
                // Find Changes where document is a diff
                snapshots.documentChanges.forEach { diff in
                    if diff.type == .modified {
                        // Check if the proper field is adjusted
                        print("GROUP TRANSACTION HAS BEEN MODIFIED")
                        let data = diff.document.data()
                        
                        let isTransactionCompleted = data["isCompleted"] as? Bool ?? false
                        print(isTransactionCompleted)
                        
                        // Alert if modified document is true
                        if isTransactionCompleted {
                            isAlert = true
                        }
                        
//                        if diff.document.documentID == user.selectedTransaction?.transaction_id {
//                            
//                        } else {
//                            print("SELECTED DOCUMENT NOT MATCH DIF")
//                        }
                    }
                    else if diff.type == .added {
                        print("NEW TRANSACTION CREATED FOR GROUP")
                        // Update Transaction List append
                        Task {
                            if let transactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup?.groupID) {
                                DispatchQueue.main.async {
                                    user.currentSelectedGroupTransactions = transactions // Store all transactions
                                    totalSpent = transactions.map { transaction in
                                        transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
                                    }
                                }
                            } else {
                                print("No transactions found for group \(selectedGroup?.groupID ?? "")")
                            }
                        }
                    }
                    
                }
            }
    }

    private func createTransaction() async {
        let scannedItems = scanReceipt.receiptItems // Assume these are the scanned receipt items
        let transactionItems = scannedItems.map { Item(priceInCents: Int($0.price * 100), name: $0.name) }
        let newTransaction = Transaction(transaction_id: "", itemList: transactionItems, itemBidders: [:], name: "New Transaction from Receipt")
        await DatabaseAPI.createTransaction(transactionData: newTransaction, groupID: selectedGroup?.groupID)
    }
    
    private func loadTransactions() async {
        print("Loading transactions for group ID: \(selectedGroup?.groupID ?? "Unknown")")
        
        if let transactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup?.groupID) {
            DispatchQueue.main.async {
                user.currentSelectedGroupTransactions = transactions // Store all transactions
                totalSpent = transactions.map { transaction in
                    transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
                }

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

