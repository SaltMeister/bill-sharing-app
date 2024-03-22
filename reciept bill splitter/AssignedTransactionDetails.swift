import SwiftUI
import StripePaymentSheet

struct AssignedTransactionDetails: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @EnvironmentObject var user: UserViewModel
    @Binding var assignedTransaction: AssignedTransaction
    
    @Environment(\.dismiss) var dismiss // Use the dismiss environment value

    var body: some View {
        VStack {
            Text("Transaction Name: \(assignedTransaction.transactionName)")
                .font(.headline)
            Text("Transaction Name: \(assignedTransaction.associatedTransaction_id)")
                .font(.headline)
            Text("Amount to Pay: $\(String(format: "%.2f", Double(assignedTransaction.amountToPay) / 100))")
                .font(.subheadline)
            
            if !assignedTransaction.isPaid {
                if let paymentSheet = paymentManager.paymentSheet {
                                 PaymentSheet.PaymentButton(paymentSheet: paymentSheet) { paymentResult in
                                     // This is the completion handler
                                     paymentManager.onPaymentCompletion(result: paymentResult)
                                     if case .completed = paymentResult {
                                         // Call transferMoney function after successful payment
                                         paymentManager.transferMoney(amount: assignedTransaction.amountToPay, destinationAccountId: assignedTransaction.user_idToPay, assignedTransactionId: assignedTransaction.associatedTransaction_id)
                                         
                                         DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Optional delay to allow users to see the completion message
                                             dismiss() // Dismiss the view
                                         }
                                     }
                                 } content: {
                                     Text("Pay Now")
                                         .padding()
                                         .background(Color.blue)
                                         .foregroundColor(Color.white)
                                         .cornerRadius(10)
                                 }
                             } else {
                    Text("Loading…")
                }
                if let result = paymentManager.paymentResult {
                    switch result {
                    case .completed:
                        Text("Payment complete")
                    case .failed(let error):
                        Text("Payment failed: \(error.localizedDescription)")
                    case .canceled:
                        Text("Payment canceled.")
                    }
                }
                
            } else {
                Text("Transaction already paid")
                    .foregroundColor(.green)
            }
        }
        .onAppear(){
            print(assignedTransaction)
            paymentManager.fetchPaymentDataAndPrepareSheet(uid: user.user_id, amount: assignedTransaction.amountToPay)
            
        }
        .padding()
        .navigationBarTitle("Transaction Details", displayMode: .inline)
    }
}
