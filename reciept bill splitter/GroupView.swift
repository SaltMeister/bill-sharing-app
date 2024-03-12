//
//  GroupView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct GroupView: View {
    @State var selectedGroup: Group?
    @State var existingTransactions: Transaction?
    
    @StateObject var scanReceipt = ScanReceipt()
    @EnvironmentObject var user: UserViewModel
    var body: some View {
        VStack {
          
            Text(selectedGroup?.group_name ?? "None")
            if (selectedGroup?.owner_id == user.user_id) {
                Button {
                    // Create Transaction Flow / Camera => Picture
                    // => Upload Data to DB => Display'
                    Task{
                        guard let image = UIImage(named: "Test6") else {
                            print("Error loading Image")
                            return
                        }
                            await scanReceipt.scanReceipt(image: image)
                        
                    }
                }
            label: {
                Text("Create")
                }
            }
            Spacer()
            //BottomToolbar()
                .padding()
        }
        .onChange(of: scanReceipt.isScanning){
            if(!scanReceipt.isScanning){
                Task{
                    await createTransaction()
                }
            }
        }
        .onAppear {
            print("DISPLAYING GROUP \(user.groups[user.selectedGroupIndex])")
            selectedGroup = user.groups[user.selectedGroupIndex]
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
        
        if let transactions = try await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup?.groupID) {
            existingTransactions = transactions.first // Store the first transaction in the array
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
