//
//  ManualTransactionView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 3/17/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

/*struct ManualTransactionInputView: View {
    @Binding var isPresented: Bool
    @Binding var transactionName: String
    @Binding var transactionPrice: String
    let groupID: String

    
    //var addTransaction: () -> Void
    
    @State private var items: [ItemInput] = [ItemInput()]
        
        var body: some View {
            NavigationView {
                Form {
                    TextField("Transaction Name", text: $transactionName)
                    
                    ForEach(items.indices, id: \.self) { index in
                                        Section(header: Text("Item \(index + 1)")) {
                                            TextField("Item Name", text: $items[index].name)

                                            HStack {
                                                Text("$")
                                                TextField("0.99 Enter Price", text: $items[index].price)
                                                    .keyboardType(.decimalPad)
                                            }
                                        }
                                        Button(action: {
                                                items.remove(at: index)
                                            }) {
                                                Image(systemName: "trash")
                                            }
                    }
                    
                    Button(action: {
                        items.append(ItemInput())
                    }) {
                        Text("Add Item")
                    }
                    
                    Button("Add Transaction") {
                        // Handle adding transaction here
                        addTransaction()
                        isPresented = false // Dismiss the sheet after adding transaction
                    }
                }
                .navigationTitle("Add Transaction")
                .navigationBarItems(trailing: Button("Cancel") {
                    isPresented = false
                })
            }
        }
    func addTransaction() {
            // Convert price to cents
            let transactionItems = items.map { Item(priceInCents: Int(($0.price as NSString).doubleValue * 100), name: $0.name) }
            
            // Create a transaction object
            let newTransaction = Transaction(transaction_id: "", itemList: transactionItems, itemBidders: [:], name: transactionName, isCompleted: false)
            
            // Call the DatabaseAPI to store the transaction
            Task {
                await DatabaseAPI.createTransaction(transactionData: newTransaction, groupID: groupID)
            }
        }
    }

    struct ItemInput {
        var name: String = ""
        var price: String = ""
    }*/
struct ManualTransactionInputView: View {
    @Binding var isPresented: Bool
    @Binding var transactionName: String
    @Binding var transactionPrice: String
    let groupID: String
    
    @State private var items: [ItemInput] = [ItemInput()]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Transaction Name", text: $transactionName)
                
                ForEach(items.indices, id: \.self) { index in
                    Section(header: transactionSectionHeader(index: index)) {
                        TextField("Item Name", text: $items[index].name)
                        
                        HStack {
                            Text("$")
                            TextField("0.99 Enter Price", text: $items[index].price)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Button(action: {
                    items.append(ItemInput())
                }) {
                    Text("Add Item")
                }
                
                Button("Add Transaction") {
                    // Handle adding transaction here
                    addTransaction()
                    isPresented = false // Dismiss the sheet after adding transaction
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
    
    func transactionSectionHeader(index: Int) -> some View {
        HStack {
            Text("Item \(index + 1)")
            Spacer()
            if index >= 0 {
                Button(action: {
                    items.remove(at: index)
                }) {
                    Image(systemName: "trash")
                }
            }
        }
    }
    
    func addTransaction() {
        // Convert price to cents
        let transactionItems = items.map { Item(priceInCents: Int(($0.price as NSString).doubleValue * 100), name: $0.name) }
        
        // Create a transaction object
        let newTransaction = Transaction(transaction_id: "", itemList: transactionItems, itemBidders: [:], name: transactionName, isCompleted: false, dateCreated: nil)
        
        // Call the DatabaseAPI to store the transaction
        Task {
            await DatabaseAPI.createTransaction(transactionData: newTransaction, groupID: groupID)
        }
    }
}

struct ItemInput {
    var name: String = ""
    var price: String = ""
}
