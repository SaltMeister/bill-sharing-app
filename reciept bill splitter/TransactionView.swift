import SwiftUI

struct TransactionView: View {
    let transaction: Transaction
    var totalSpent: Double {
           return transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
       }
    var body: some View {
        VStack {
            Text(transaction.name)
                .font(.title)
            
            List {
                ForEach(transaction.itemList.indices, id: \.self) { index in
                    Text("\(transaction.itemList[index].name): $\(String(format: "%.2f", Double(transaction.itemList[index].priceInCents) / 100))")
                }
            }
            Text("Total Spent: $\(String(format: "%.2f", totalSpent))")
                                .fontWeight(.bold)
        }
        .navigationTitle("Transaction Details")
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView(transaction: Transaction(itemList: [Item(priceInCents: 500, name: "Item 1"), Item(priceInCents: 750, name: "Item 2")], itemBidders: [:], name: "Test Transaction"))
    }
}
