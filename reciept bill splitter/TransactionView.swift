import SwiftUI

struct TransactionView: View {

    @EnvironmentObject var user: UserViewModel
    
    let transaction: Transaction
    var totalSpent: Double {
           return transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
       }
    var body: some View {
        VStack {
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
        }
        .navigationTitle("Transaction Details")


        Button("Complete Transaction") {
            Task {
                await DatabaseAPI.toggleGroupTransactionsCompletion(groupID: user.groups_id?[user.selectedGroupIndex] ?? "", completion: true)
            }
        }
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView(transaction: Transaction(itemList: [Item(priceInCents: 500, name: "Item 1"), Item(priceInCents: 750, name: "Item 2")], itemBidders: [:], name: "Test Transaction"))
    }
}
