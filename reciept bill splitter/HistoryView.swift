import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct HistoryView: View {
    @EnvironmentObject var user: UserViewModel
    @State private var allTransactions: [Transaction] = []
    
    var body: some View {
        List {
            ForEach(allTransactions.indices, id: \.self) { index in
                Text(allTransactions[index].name)
                // Display other transaction details as needed
            }
        }
        .onAppear {
            fetchAllTransactions()
        }
    }
    
    private func fetchAllTransactions() {
        Task {
            var transactions: [Transaction] = []
            // Fetch transactions for each group
            for group in user.groups {
                if let groupTransactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: group.groupID) {
                    transactions.append(contentsOf: groupTransactions)
                }
            }
            // Sort transactions by time created
            transactions.sort { $0.timeCreated > $1.timeCreated }
            
            DispatchQueue.main.async {
                allTransactions = transactions
            }
        }
    }
}
