import SwiftUI

struct AccountView: View {
    @State private var isEditing = false
    @State private var newUsername = ""
    @EnvironmentObject var user: UserViewModel
    @EnvironmentObject var paymentManager: PaymentManager // Assuming PaymentManager is available as an EnvironmentObject
    @State private var balanceData: [String: Any]? = nil

    var body: some View {
        VStack {
            HStack {
                if isEditing {
                    TextField("Enter new username", text: $newUsername)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text("Current Username: " + newUsername)
                        .padding()
                }
                Button(action: {
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(isEditing ? .green : .blue)
                }
            }
            
            if isEditing {
                Button("Save") {
                    Task {
                        await user.createUserInDB(username: newUsername)
                        isEditing.toggle()
                    }
                }
                .padding()
            }
            
            // Stripe balance section
            if let balanceData = balanceData {
                VStack {
                    Text("Stripe Balance")
                        .font(.title)
                        .padding()
                    if let availableArray = balanceData["available"] as? [[String: Any]],
                       let available = availableArray.first,
                       let availableAmount = available["amount"] as? Int {
                        Text("Available Balance: \(formatAmount(availableAmount))")
                    }
                    if let pendingArray = balanceData["pending"] as? [[String: Any]],
                       let pending = pendingArray.first,
                       let pendingAmount = pending["amount"] as? Int {
                        Text("Pending Balance: \(formatAmount(pendingAmount))")
                    }
                }
            } else {
                Text("Loading balance...")
            }
        }
        .navigationTitle("Accounts")
        .onAppear {
            fetchStripeBalance()
        }
    }
    
    private func fetchStripeBalance() {
        // Check if the current user has a Stripe Connect Account ID
        DatabaseAPI.getStripeConnectAccountId { accountId, error in
            guard let accountId = accountId, error == nil else {
                print("Stripe Connect Account ID not found or error occurred: \(error?.localizedDescription ?? "Unknown error")")
                // Handle UI update for users without Stripe account here
                // For example, show a message or hide the balance section
                return
            }
            
            // If the account ID exists, fetch the Stripe balance
            paymentManager.checkStripeBalance(accountId: accountId) { result in
                switch result {
                case .success(let balance):
                    // Here you can update some state to display the balance in your UI
                    self.balanceData = balance
                    print("Retrieved Stripe balance: \(balance)")
                case .failure(let error):
                    print("Error fetching Stripe balance: \(error.localizedDescription)")
                }
            }
        }
    }

    private func formatAmount(_ amount: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = "USD"
        return numberFormatter.string(from: NSNumber(value: Double(amount) / 100)) ?? "$0.00"
    }
}
