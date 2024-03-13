import SwiftUI

struct TransactionView: View {

    @EnvironmentObject var user: UserViewModel
    
    @State var selectedGroup: Group?
    
    var totalSpent: Double {
        print(user.selectedTransaction)
        
        if let transaction = user.selectedTransaction {
            return transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
        } else {
            return Double(0.0)
        }
    }
    
    var body: some View {
        VStack {
            if let transaction = user.selectedTransaction {
                
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
                Text("Total Spent: $\(String(format: "%.2f", totalSpent))")
                    .fontWeight(.bold)
            } else {
                Text("ViewModel Did not Update Transactions")
            }
            
            // ONLY group owner can lock in assigned prices
            if selectedGroup?.groupID == user.user_id {
                Button("Complete Transaction") {
                    Task {
                        await DatabaseAPI.toggleGroupTransactionsCompletion(groupID: user.groups_id?[user.selectedGroupIndex] ?? "", completion: true)
                    }
                }
            }
        }
        .onAppear {
            selectedGroup = user.groups[user.selectedGroupIndex]
            
        }
        .navigationTitle("Transaction Details")
        

    }
}
