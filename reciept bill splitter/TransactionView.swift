import SwiftUI

struct TransactionView: View {

    @EnvironmentObject var user: UserViewModel
    
    @Binding var selectedTransactionId: String
    @Binding var groupData: Group
    
    @State var transactionData: Transaction?
    
    var totalSpent: Double {
        
        if let transaction = user.selectedTransaction {
            return transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
        } else {
            return Double(0.0)
        }
    }
    
    var body: some View {
        VStack {
            if let transaction = transactionData {
                
                Text(transaction.name)
                    .font(.title)
                // index of the bidding members and get the dictiionary count inside
                List {
                    ForEach(transaction.itemList.indices, id: \.self) { index in
                        let bidders = transaction.itemBidders[String(index)] ?? []
                        let biddersCount = bidders.count
                        let isCurrentUserBidding = bidders.contains(user.user_id)
                        
                        HStack {
                            Text("\(transaction.itemList[index].name): $\(String(format: "%.2f", Double(transaction.itemList[index].priceInCents) / 100))")
                                .foregroundColor(isCurrentUserBidding ? .blue : .primary) // Change color if the current user is bidding
                            Spacer()
                            // Display the number of bidders for each item
                            Text("Bidders: \(biddersCount)")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                }
                Text("Your Total Contribution: $\(String(format: "%.2f", calculateUserTotalContribution(transaction: user.selectedTransaction!, userID: user.user_id)))")
                    .fontWeight(.bold)

                Text("Total: $\(String(format: "%.2f", totalSpent))")
                    .fontWeight(.bold)
                
            } else {
                Text("LOADING")
            }
            
            // ONLY group owner can lock in assigned prices
            if groupData.owner_id == user.user_id {
                Button("Complete Transaction") {
                    Task {
                        await DatabaseAPI.toggleGroupTransactionsCompletion(transactionID: user.selectedTransaction?.transaction_id ?? "", completion: true)
                    }
                }
            }
        }
        .onAppear {
            Task {
                transactionData = await DatabaseAPI.grabTransaction(transaction_id: selectedTransactionId)
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

}
