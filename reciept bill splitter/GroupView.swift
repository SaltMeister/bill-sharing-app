import SwiftUI

struct GroupView: View {
    @State var selectedGroup: Group?
    @State var existingTransactions: Transaction?
    @State private var totalSpent: Double = 0.0
    @StateObject var scanReceipt = ScanReceipt()
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        VStack {
            Text(selectedGroup?.group_name ?? "None")
            
            if let transactions = existingTransactions {
                List {
                    ForEach(transactions.itemList.indices, id: \.self) { index in
                        Text("\(transactions.itemList[index].name): $\(String(format: "%.2f", Double(transactions.itemList[index].priceInCents) / 100))")

                    }
                    
                }
            } else {
                Text("No transactions found")
            }
            
            if (selectedGroup?.owner_id == user.user_id) {
                Button {
                    // Create Transaction Flow / Camera => Picture
                    // => Upload Data to DB => Display'
                    Task {
                        guard let image = UIImage(named: "Test6") else {
                            print("Error loading Image")
                            return
                        }
                        await scanReceipt.scanReceipt(image: image)
                    }
                } label: {
                    Text("Create")
                }
            }
            
            Spacer()
            
            Text("Total Spent: $\(String(format: "%.2f", totalSpent))") // Added this line
                            .padding(.bottom) // Added this line
            //BottomToolbar()
                .padding()
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
        
        if let transactions = try await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup?.groupID) {
            existingTransactions = transactions.first // Store the first transaction in the array
            totalSpent = transactions.map { $0.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +) }.reduce(0, +)

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
