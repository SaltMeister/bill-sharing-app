import StripePaymentSheet
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
}
