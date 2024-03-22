import SwiftUI
import Firebase
import SwiftUI
import StripePaymentSheet

struct TransactionView: View {

    @EnvironmentObject var user: UserViewModel
    
    @Binding var selectedTransactionId: String
    @Binding var groupData: Group
    
    @State var transactionData: Transaction?
    
    var body: some View {
        VStack {
            if let transaction = transactionData {
                let totalSpent = transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
                
                Text(transaction.name)
                    .font(.title)
                // index of the bidding members and get the dictiionary count inside
                List {
                    ForEach(transaction.itemList.indices, id: \.self) { index in
                        let isCurrentUserBidding = transaction.itemBidders[String(index)]?.contains(user.user_id) ?? false
                        
                        HStack {
                            Text("\(transaction.itemList[index].name): $\(String(format: "%.2f", Double(transaction.itemList[index].priceInCents) / 100))")
                            Spacer()
                            Button(action: {
                                Task {
                                    await bidOnItem(itemIndex: index, transactionID: transaction.transaction_id, userID: user.user_id)
                                    transactionData = await DatabaseAPI.grabTransaction(transaction_id: selectedTransactionId)

                                }
                            }) {
                                Text(isCurrentUserBidding ? "Unbid" : "Bid")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(isCurrentUserBidding ? Color.red : Color.green)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }

                Text("Your Total Contribution: $\(String(format: "%.2f", calculateUserTotalContribution(transaction: transaction, userID: user.user_id)))")
                    .fontWeight(.bold)

                Text("Total: $\(String(format: "%.2f", totalSpent))")
                    .fontWeight(.bold)
                
                // ONLY group owner can lock in assigned prices
                if groupData.owner_id == user.user_id {
                    Button("Complete Transaction") {
                        Task {
                            await DatabaseAPI.toggleGroupTransactionsCompletion(transactionID: transaction.transaction_id, completion: true)
                        }
                    }
                }
                
            } else {
                Text("LOADING")
            }
            

        }
        .onAppear {
            Task {
                transactionData = await DatabaseAPI.grabTransaction(transaction_id: selectedTransactionId)
            }
        }
        .onAppear {
            let transactionRef = Firestore.firestore().collection("transactions").document(selectedTransactionId)
            transactionRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot, error == nil else {
                    print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                // Parse the data into your Transaction model and update the state
               // self.transactionData = self.parseTransactionData(data)
            }
        }

        .navigationTitle("Transaction Details")
        

    }
    func calculateUserTotalContribution(transaction: Transaction, userID: String) -> Double {
        var totalContribution: Double = 0.0

        for (index, item) in transaction.itemList.enumerated() {
            if let bidders = transaction.itemBidders[String(index)], bidders.contains(userID) {
                // If the user is bidding on the item, split the cost among all bidders
                let pricePerBidder = Double(item.priceInCents) / 100.0 / Double(bidders.count)
                totalContribution += pricePerBidder
            }
        }

        return totalContribution
    }
    func bidOnItem(itemIndex: Int, transactionID: String, userID: String) async {
        let transactionRef = Firestore.firestore().collection("transactions").document(transactionID)
        
        do {
            let document = try await transactionRef.getDocument()
            if document.exists, var transactionData = document.data() {
                var itemBidders = transactionData["itemBidders"] as? [String: [String]] ?? [:]
                var bidders = itemBidders[String(itemIndex)] ?? []
                
                if let index = bidders.firstIndex(of: userID) {
                    // User is already bidding, remove their bid
                    bidders.remove(at: index)
                } else {
                    // Add user's bid
                    bidders.append(userID)
                }
                
                // Update the bidders list for the item
                itemBidders[String(itemIndex)] = bidders
                transactionData["itemBidders"] = itemBidders
                
                // Update the transaction document
                try await transactionRef.updateData(transactionData)
            }
        } catch {
            print("Error updating transaction: \(error)")
        }
    }

//    func parseTransactionData(_ data: [String: Any]) -> Transaction {
//        // Parse the data into your Transaction model
//        // Example:
//        let name = data["name"] as? String ?? "Unknown"
//        let itemList = data["itemList"] as? [[String: Any]] ?? []
//        let itemObjects = itemList.map { itemData -> Item in
//            let name = itemData["name"] as? String ?? "Item"
//            let priceInCents = itemData["priceInCents"] as? Int ?? 0
//            return Item(priceInCents: priceInCents, name: name)
//        }
//        return Transaction(name: name, itemList: itemObjects, ...)
//    }

}
