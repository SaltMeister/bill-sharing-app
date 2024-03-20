import StripePaymentSheet
import FirebaseFunctions
import SwiftUI

class PaymentManager: ObservableObject {
    @Published var paymentResult: PaymentSheetResult?
    @Published var  paymentSheet: PaymentSheet?
    
    var clientSecret: String?
    
    func preparePaymentSheet(customerId: String, ephemeralKey: String) {
        // Ensure the clientSecret is set
        guard let clientSecret = self.clientSecret else {
            print("Client secret is not set.")
            return
        }
        
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
        
        DispatchQueue.main.async {
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
        }
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
    }
    
    
    func fetchPaymentDataAndPrepareSheet(uid: String, amount: Int) {
        DatabaseAPI.retrieveStripeCustomerId(uid: uid) { [weak self] customerId in
            guard let self = self, let customerId = customerId else {
                print("No Stripe Customer ID found for this UID.")
                return
            }
            
            // Fetch Ephemeral Key and PaymentIntent client secret
            self.fetchEphemeralKeyAndClientSecret(customerId: customerId, amount: amount) { clientSecret, ephemeralKey in
                self.preparePaymentSheet(customerId: customerId, ephemeralKey: ephemeralKey)
            }
        }
    }
    
    private func fetchEphemeralKeyAndClientSecret(customerId: String, amount: Int, completion: @escaping (String, String) -> Void) {
        let functions = Functions.functions()
        functions.httpsCallable("createEphemeralKey").call(["customerId": customerId, "apiVersion": "2020-08-27"]) { [weak self] result, error in
            guard let self = self, let ephemeralKey = (result?.data as? [String: Any])?["key"] as? String else {
                print("Error fetching ephemeral key:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            // Use the passed amount for the PaymentIntent
            functions.httpsCallable("createPaymentIntent").call(["amount": amount, "stripeCustomerId": customerId]) { result, error in
                guard let clientSecret = (result?.data as? [String: Any])?["clientSecret"] as? String else {
                    print("Error creating PaymentIntent:", error?.localizedDescription ?? "Unknown error")
                    return
                }
                DispatchQueue.main.async {
                    self.clientSecret = clientSecret
                    completion(clientSecret, ephemeralKey)
                    
                }
            }
        }
    }
    
    func createExpressAccount(email: String){
        let data: [String: Any] = [
            "email": email
        ]
        
        Functions.functions().httpsCallable("createExpressAccount").call(data) { (result, error) in
            if let error = error as NSError? {
                print("Error calling createExpressAccount:", error.localizedDescription)
                return
            }
            
            guard let accountID = (result?.data as? [String: Any])?["accountId"] as? String else {
                print("Error parsing account ID from createExpressAccount function result")
                return
            }
            print("Created Express Account with ID:", accountID)
            DatabaseAPI.setStripeConnectAccountId(accountId: accountID) { error in
                if let error = error {
                    print("Error setting Stripe Connect Account ID in Firestore: \(error.localizedDescription)")
                } else {
                    print("Stripe Connect Account ID set successfully in Firestore.")
                }
            }
            //                                    // Proceed with your app flow, now that the account is created
            //
        }
    
    }
     func createStripeAccountLink(stripeAccountID: String) {
            let functions = Functions.functions()
        functions.httpsCallable("createAccountLink").call(["accountId": stripeAccountID]) { result, error in
                if let error = error as NSError? {
                    // Handle error from Cloud Function call
                    print(error.localizedDescription)
                    return
                }else {print("error creating link1")}

                if let accountLinkURLString = (result?.data as? [String: Any])?["url"] as? String,
                   let url = URL(string: accountLinkURLString) {
                    print("URL:", url)  // This line prints the URL to the console

                    DispatchQueue.main.async {
                    
                        UIApplication.shared.open(url)
                        
                        print("safari true")
                    }
                }else {print("error creating link2")}
            }
        
        }
    func transferMoney(amount: Int, destinationAccountId: String) {
        let functions = Functions.functions()
        functions.httpsCallable("createTransfer").call(["amount": amount, "destinationAccountId": destinationAccountId]) { result, error in
            if let error = error {
                print("Error transferring money: \(error.localizedDescription)")
                return
            }
            if let transferId = (result?.data as? [String: Any])?["transferId"] as? String {
                print("Transfer successful, transferId: \(transferId)")
            } else {
                print("Transfer failed")
            }
        }
    }
}
