import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @State private var isEditing = false
    @State private var newUsername = ""
    @State private var userEmail = "" // Add state to store user email
    @State private var userCanGetPaid = false // Add state to store user email
    @State private var user_id = ""

    @EnvironmentObject var user: UserViewModel
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var balanceData: [String: Any]? = nil
    @State var isLoggedOut = false

    var body: some View {
        NavigationStack{
            VStack {
                HStack {
                    if isEditing {
                        TextField("Enter new username", text: $newUsername)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text("Current Username: " + (newUsername.isEmpty ? "N/A" : newUsername))
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
                            await user.updateUserName(newName: newUsername)
                            isEditing.toggle()
                        }
                    }
                    .padding()
                }
                Text("Email: \(userEmail)") // Display user email
                    .padding()
                // Stripe balance section
                if user.canGetPaid {
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
                            Button("Update payment methods") {
                                print("creating link")
                                DatabaseAPI.getStripeConnectAccountId { accountId, error in
                                    if let error = error {
                                        print("Error retrieving account ID: \(error.localizedDescription)")
                                    } else if let accountId = accountId {
                                        print("Retrieved Stripe Connect Account ID: \(accountId)")
                                        // Use the accountId for whatever you need, like creating an account link
                                        paymentManager.createStripeAccountLink(stripeAccountID: accountId)
                                    } else {
                                        print("Stripe Connect Account ID not found")
                                    }
                                }
                            }
                        }
                    } else {
                        Text("")
                    }
                }
                else {
                    Button("Setup Payments") {
                        print("creating account")
                        paymentManager.createExpressConnectAccountAndOnboardingLink(email: userEmail)
                        
                        //SETUP after onboarding it is the only way and have to check for reauth fuckkkkkkkkkkk (setup the cangetpaid of course)
                        
                        DatabaseAPI.setCanGetPaid(forUserId: user_id, canGetPaid: true) { error in // Pass the userId here
                            if let error = error {
                                // Handle the error
                                print("Error setting canGetPaid: \(error.localizedDescription)")
                            } else {
                                // Update was successful
                                self.userCanGetPaid = true
                                user.canGetPaid = true
                                print("canGetPaid successfully set for the user")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .onAppear {
                Task{
                    await fetchUserDetails()
                    await fetchStripeBalance()
                    await user.updateCanGetPaidStatus()
                    
                }
            }
            Button(action: {
                // Sign out action
                do {
                    try Auth.auth().signOut()
                    isLoggedOut = true // Set isLoggedIn to false to navigate to SignUpView
                    
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }) {
                Text("Sign Out")
                    .foregroundColor(.red)
            }
            .padding()
        }
        .navigationDestination(isPresented: $isLoggedOut) {
                    SignUpLogInView(isLoggedIn: $isLoggedOut)
                    .navigationBarHidden(true)

        }
    }
    
    
    
    private func fetchUserDetails() async{
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
