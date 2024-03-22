import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AllAssignedTransactions: View {
    @EnvironmentObject var user: UserViewModel
    @State var allAssignedTransactions: [AssignedTransaction] = []
    
    var body: some View {
        NavigationStack {
            Text("Assigned Transactions")
            List {
                ForEach(0 ..< allAssignedTransactions.count, id:\.self) { index in
                    NavigationLink(destination: AssignedTransactionDetails(assignedTransaction: $allAssignedTransactions[index])) {
                        VStack(alignment: .leading) {
                            if allAssignedTransactions[index].isPaid {
                                Text(allAssignedTransactions[index].transactionName)
                                    .opacity(0.5)
                            }
                            else {
                                Text(allAssignedTransactions[index].transactionName)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchAllTransactions()
        }
    }
    
    private func fetchAllTransactions() {
        Task {
            if let userAssignedTransactions = await DatabaseAPI.grabUserAssignedTransactions() {
                allAssignedTransactions = userAssignedTransactions
            }
        }
    }
}
