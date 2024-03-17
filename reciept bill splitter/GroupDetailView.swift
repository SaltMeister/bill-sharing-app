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
    let db = Firestore.firestore()
    @State private var isCameraPresented = false
    @State private var isTransactionSelected = false
    @State private var selectedImage: UIImage?
    @State private var isTaken = false
    @State private var existingTransactions: [Transaction] = []
    @State private var totalSpent: Double = 0
    
    @State private var isManualInputPresented = false
    @State private var transactionName = ""
    @State private var transactionPrice = ""
    
    @State var selectedGroup: Group?
    @State var isAlert = false
    
    @StateObject var scanReceipt = ScanReceipt()
    @EnvironmentObject var user: UserViewModel

    var body: some View {
        NavigationStack {
            VStack {
                if !user.currentSelectedGroupTransactions.isEmpty {
                    List {
                        ForEach(user.currentSelectedGroupTransactions.indices, id: \.self) { index in
                            if user.currentSelectedGroupTransactions[index].isCompleted {
                                HStack {
                                    Text(user.currentSelectedGroupTransactions[index].name)
                                }
                                .onTapGesture {
                                    user.selectedTransaction = user.currentSelectedGroupTransactions[index]
                                    isTransactionSelected = true
                                }
                                .opacity(0.5)
                            } else {
                                HStack {
                                    Text(user.currentSelectedGroupTransactions[index].name)
                                }
                                .onTapGesture {
                                    user.selectedTransaction = user.currentSelectedGroupTransactions[index]
                                    isTransactionSelected = true
                                }
                            }
                        }
                    }
                    Button("Add Transaction") {
                        isManualInputPresented.toggle()
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
            .navigationDestination(isPresented: $isTransactionSelected) {
                TransactionView()
            }
            .navigationDestination(isPresented: $isManualInputPresented) {
                //ManualTransactionInputView(isPresented: $isManualInputPresented, transactionName: $transactionName, transactionPrice: $transactionPrice, addTransaction: addTransaction)
                ManualTransactionInputView(isPresented: $isManualInputPresented, transactionName: $transactionName, transactionPrice: $transactionPrice, groupID: selectedGroup?.groupID ?? "")
                
            }
            .onChange(of: scanReceipt.isScanning) {
                if !scanReceipt.isScanning {
                    Task {
                        await createTransaction()
                    }
                }
            }
            .onAppear {
                if let selectedGroup = selectedGroup {
                    print("DISPLAYING GROUP \(selectedGroup.group_name)")
                    self.selectedGroup = selectedGroup
                    Task {
                        await loadTransactions()
                        listenToDocuments()
                    }
                }
            }
        }
    }
    
    /*private func addTransaction() {
            // Add the transaction to the database or perform any other necessary actions
            // You can access the entered transaction details from transactionName, transactionPrice, etc.
            let newItem = Item(priceInCents: Int(transactionPrice) ?? 0, name: transactionName)
            let newTransaction = Transaction(transaction_id: UUID().uuidString, itemList: [newItem], itemBidders: [:], name: transactionName, isCompleted: false)
            user.currentSelectedGroupTransactions.append(newTransaction)
            isManualInputPresented = false
    }*/
    
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
                                    }.reduce(0, +)
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
        let newTransaction = Transaction(transaction_id: "", itemList: transactionItems, itemBidders: [:], name: scanReceipt.title ?? "Untitled Transaction", isCompleted: false)
        await DatabaseAPI.createTransaction(transactionData: newTransaction, groupID: selectedGroup?.groupID)
    }
    
    private func loadTransactions() async {
        print("Loading transactions for group ID: \(selectedGroup?.groupID ?? "Unknown")")
        
        if let transactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup?.groupID) {
            DispatchQueue.main.async {
                user.currentSelectedGroupTransactions = transactions // Store all transactions
                totalSpent = transactions.map { transaction in
                    transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
                }.reduce(0, +)
            }
        } else {
            print("No transactions found for group \(selectedGroup?.groupID ?? "")")
        }
    }
}
