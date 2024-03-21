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
    
    @State private var isViewMembersPopoverPresented = false
    
    @State private var isManualInputPresented = false

    
    @State private var transactionName = ""
    @State private var transactionPrice = ""
    
    @State var selectedGroup: Group
    @State private var selectedTransactionID = ""
    
    @State var isAlert = false
    
    @StateObject var scanReceipt = ScanReceipt()
    @EnvironmentObject var user: UserViewModel

    var body: some View {
        NavigationStack {
            VStack {
                if !user.currentSelectedGroupTransactions.isEmpty {
                    List {
                        ForEach(user.currentSelectedGroupTransactions.indices, id: \.self) { index in
                            print(user.currentSelectedGroupTransactions[index].dateCreated)
                            if user.currentSelectedGroupTransactions[index].isCompleted {
                                HStack {
                                    Text(user.currentSelectedGroupTransactions[index].name)
                                }
                                .onTapGesture {
                                    user.selectedTransaction = user.currentSelectedGroupTransactions[index]
                                    selectedTransactionID = user.currentSelectedGroupTransactions[index].transaction_id
                                    isTransactionSelected = true
                                }
                                .opacity(0.5)
                            } else {
                                HStack {
                                    Text(user.currentSelectedGroupTransactions[index].name)
                                }
                                .onTapGesture {
                                    user.selectedTransaction = user.currentSelectedGroupTransactions[index]
                                    selectedTransactionID = user.currentSelectedGroupTransactions[index].transaction_id
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
                
                if selectedGroup.owner_id == user.user_id {
                    Button("Open Camera") {
                        Task {
                            await createTransaction()
                        }
                        //isCameraPresented = true
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
                
                Button(action: {
                    isViewMembersPopoverPresented.toggle()
                }) {
                    Label("View Members", systemImage: "person.2.fill")
                }
                .popover(isPresented: $isViewMembersPopoverPresented, arrowEdge: .bottom) {
                    MembersListView(members: selectedGroup.members)
                }
            }
            .navigationDestination(isPresented: $isTransactionSelected) {
                TransactionView(selectedTransactionId: $selectedTransactionID, groupData: $selectedGroup)
            }
            .navigationDestination(isPresented: $isManualInputPresented) {
                ManualTransactionInputView(isPresented: $isManualInputPresented, transactionName: $transactionName, transactionPrice: $transactionPrice, groupID: selectedGroup.groupID)
            }
            .onChange(of: scanReceipt.isScanning) {
                if !scanReceipt.isScanning {
                    Task {
                        await createTransaction()
                    }
                }
            }
            .onAppear {
                print("DISPLAYING GROUP \(selectedGroup.group_name)")
                print("Member IDs: \(selectedGroup.members.map { $0.id })") // Print member IDs
                self.selectedGroup = selectedGroup
                Task {
                    await loadTransactions()
                }
            }
        }
    }
    
    private func createTransaction() async {
        let scannedItems = scanReceipt.receiptItems // Assume these are the scanned receipt items
        let transactionItems = scannedItems.map { Item(priceInCents: Int($0.price * 100), name: $0.name) }
        let tempTransaction = Transaction(transaction_id: "", itemList: [], itemBidders: [:], name: scanReceipt.title ?? "Untitled Transaction", isCompleted: false, dateCreated: nil)
        
        let newTransaction = Transaction(transaction_id: "", itemList: transactionItems, itemBidders: [:], name: scanReceipt.title ?? "Untitled Transaction", isCompleted: false, dateCreated: nil)
       
        await DatabaseAPI.createTransaction(transactionData: tempTransaction, groupID: selectedGroup.groupID)
    }
    
    private func loadTransactions() async {
        print("Loading transactions for group ID: \(selectedGroup.groupID)")
        
        if let transactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup.groupID) {
            DispatchQueue.main.async {
                user.currentSelectedGroupTransactions = transactions // Store all transactions
                totalSpent = transactions.map { transaction in
                    transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
                }.reduce(0, +)
            }
        } else {
            print("No transactions found for group \(selectedGroup.groupID)")
        }
    }
}

struct MembersListView: View {
    let members: [GroupMember]
    
    var body: some View {
        List {
            ForEach(members, id: \.id) { member in
                Text(member.id)
            }
        }
        .onAppear {
                    print("Members: \(members)")
                }
    }
}


