
import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @State private var isEditing = false
    @State private var newUsername = ""
    @State private var userEmail = ""
    @State private var userCanGetPaid = false
    @State private var user_id = ""

    @EnvironmentObject var user: UserViewModel
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var balanceData: [String: Any]? = nil
    @Environment(\.dismiss) var dismiss
    
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        if isEditing {
                            TextField("Enter new username", text: $newUsername)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical)
                        } else {
                            Text("Current Username: \(newUsername.isEmpty ? "N/A" : newUsername)")
                                .foregroundColor(.primary)
                                .font(.headline)
                                .padding(.vertical)
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
                                await user.updateUserName(newName: newUsername)
                                isEditing.toggle()
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.blue).opacity(0.3))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Email: \(userEmail)")
                        .foregroundColor(.primary)
                        .font(.headline)
                        .padding(.vertical)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.blue).opacity(0.3))

                if user.canGetPaid {
                    if let balanceData = balanceData {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Stripe Balance")
                                .font(.title)
                                .foregroundColor(.primary)

                            if let availableArray = balanceData["available"] as? [[String: Any]],
                               let available = availableArray.first,
                               let availableAmount = available["amount"] as? Int {
                                Text("Available Balance: \(formatAmount(availableAmount))")
                                    .foregroundColor(.primary)
                            }

                            if let pendingArray = balanceData["pending"] as? [[String: Any]],
                               let pending = pendingArray.first,
                               let pendingAmount = pending["amount"] as? Int {
                                Text("Pending Balance: \(formatAmount(pendingAmount))")
                                    .foregroundColor(.primary)
                            }

                            Button("Update payment methods") {
                                print("Creating link")
                                DatabaseAPI.getStripeConnectAccountId { accountId, error in
                                    if let error = error {
                                        print("Error retrieving account ID: \(error.localizedDescription)")
                                    } else if let accountId = accountId {
                                        print("Retrieved Stripe Connect Account ID: \(accountId)")
                                        paymentManager.createStripeAccountLink(stripeAccountID: accountId)
                                    } else {
                                        print("Stripe Connect Account ID not found")
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.blue).opacity(0.3))
                    }
                } else {
                    Button("Setup Payments") {
                        print("Creating account")
                        paymentManager.createExpressConnectAccountAndOnboardingLink(email: userEmail)

                        DatabaseAPI.setCanGetPaid(forUserId: user_id, canGetPaid: true) { error in
                            if let error = error {
                                print("Error setting canGetPaid: \(error.localizedDescription)")
                            } else {
                                self.userCanGetPaid = true
                                user.canGetPaid = true
                                print("canGetPaid successfully set for the user")
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Accounts")
            .onAppear {
                Task {
                    await fetchUserDetails()
                    await fetchStripeBalance()
                    await user.updateCanGetPaidStatus()
                }
            }

            Button(action: {
                // Sign out action
                do {
                    try Auth.auth().signOut()
                    isLoggedIn = false
                    dismiss()
                    
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }) {
                Text("Sign Out")
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding()
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func fetchUserDetails() async {
        Task {
            if let user = await DatabaseAPI.grabUserData() {
                self.newUsername = user.userName
                self.userEmail = user.email
            }
            if let user = Auth.auth().currentUser {
                self.user_id = user.uid
            }
        }
    }

    private func fetchStripeBalance() async {
        DatabaseAPI.getStripeConnectAccountId { accountId, error in
            guard let accountId = accountId, error == nil else {
                print("Stripe Connect Account ID not found or error occurred: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            paymentManager.checkStripeBalance(accountId: accountId) { result in
                switch result {
                case .success(let balance):
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
