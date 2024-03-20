//
//  HomeView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI
import Firebase
import FirebaseFunctions
import SafariServices
import StripePaymentSheet

struct HomeView: View {
    
    @State private var isSplitViewActive : Bool = false
    @State private var isViewingGroup = false
    @StateObject private var paymentManager = PaymentManager()
      @State private var showPaymentSheet = false
    @State private var showSafari = false
    @State private var accountLinkURL: URL?
    
    @State private var isEmptyDisplayFormat = true
    
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                if isEmptyDisplayFormat {
                    Button {
                        Task {
                            await DatabaseAPI.createGroup()
                            await user.getUserData()
                            isEmptyDisplayFormat = false
                        }
                        
                    } label: { Text("Create Group") }
                        .font(.custom("Avenir", size: 30))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.black)
                        .cornerRadius(1)
                    
                    Button {
                        print("Join Group")
                    } label: { Text("Join Group") }
                        .font(.custom("Avenir", size: 30))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.black)
                        .cornerRadius(1)
                }
                else {
                    // Display all groups
                    ForEach(Array(user.groups.enumerated()), id: \.offset) { index, element in
                        HStack {
                            Text(element.group_name)
                            Text("Invite Code \(element.invite_code)")
                        }
                        .onTapGesture {
                            user.selectedGroupIndex = index
                            isViewingGroup = true
                            // Open Group View and display group data
                        }
                    }
                    Button("Transfer Money") {
                           transferMoney(amount: 500, destinationAccountId: "acct_1Ovoc6QQyo8likZn") // Replace "acct_XXXXX" with the actual connected account ID
                       }
                    Button("Collect Payment") {
                        if let user = Auth.auth().currentUser {
                            fetchPaymentDataAndPrepareSheet(uid: user.uid)
                        } else {
                            print("No user is signed in.")
                        }
                    }
                    VStack{
                    if let paymentSheet = paymentManager.paymentSheet {
                        PaymentSheet.PaymentButton(
                            paymentSheet: paymentSheet,
                            onCompletion: paymentManager.onPaymentCompletion
                        ) {
                            Text("Buy")
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
                }
                    Button("Connect with Stripe") {
                            print("creating account")

                            createStripeAccountLink()
                    }
                    .sheet(isPresented: $showSafari) {
                            
                            if let url = accountLinkURL {
                                SafariView(url: url)
                            }
                    }
                    Button {
                        Task {
                            await DatabaseAPI.createGroup()
                            await user.getUserData()
                        }
                    } label: {Text("Create Group") }
                        .font(.custom("Avenir", size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .cornerRadius(15)
                }
                Spacer()
                BottomToolbar()
            }
        }
        // Load Groups or create one
        .onAppear {
            Task {
                await user.getUserData()
                
                // Check if user groups is empty
                if user.groups.count > 0 {
                    isEmptyDisplayFormat = false
                }
            }
        }
        .navigationDestination(isPresented: $isSplitViewActive){
            SplitView()
            
        }
        .navigationDestination(isPresented: $isViewingGroup) {
            GroupView()
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
    func fetchPaymentDataAndPrepareSheet(uid: String) {
        // Retrieve the Stripe Customer ID
        DatabaseAPI.retrieveStripeCustomerId(uid: uid) { customerId in
            guard let customerId = customerId else {
                print("No Stripe Customer ID found for this UID.")
                return
            }

            // Fetch Ephemeral Key
            Functions.functions().httpsCallable("createEphemeralKey").call(["customerId": customerId, "apiVersion": "2020-08-27"]) { result, error in
                if let error = error {
                    print("Error fetching ephemeral key:", error.localizedDescription)
                    return
                }
                guard let ephemeralKey = (result?.data as? [String: Any])?["key"] as? String else {
                    print("Ephemeral key not found.")
                    return
                }

                // Fetch PaymentIntent client secret
                let amount = 100000 // Define the amount to be charged, e.g., $10.00
                Functions.functions().httpsCallable("createPaymentIntent").call(["amount": amount, "stripeCustomerId": customerId]) { result, error in
                    if let error = error {
                        print("Error creating PaymentIntent:", error.localizedDescription)
                        return
                    }
                    guard let clientSecret = (result?.data as? [String: Any])?["clientSecret"] as? String else {
                        print("Client secret not found.")
                        return
                    }

                    // Prepare the payment sheet
                    DispatchQueue.main.async {
                        self.paymentManager.clientSecret = clientSecret
                        self.paymentManager.preparePaymentSheet(customerId: customerId, ephemeralKey: ephemeralKey)
                    }
                }
            }
        }
    }

    private func createStripeAccountLink() {
        print(user.stripeAccountID)
            let functions = Functions.functions()
        functions.httpsCallable("createAccountLink").call(["accountId": user.stripeAccountID]) { result, error in
                if let error = error as NSError? {
                    // Handle error from Cloud Function call
                    print(error.localizedDescription)
                    return
                }else {print("error creating link1")}

                if let accountLinkURLString = (result?.data as? [String: Any])?["url"] as? String,
                   let url = URL(string: accountLinkURLString) {
                    print("URL:", url)  // This line prints the URL to the console

                    DispatchQueue.main.async {
                        self.accountLinkURL = url
                        print("url here ",accountLinkURL! )
                        UIApplication.shared.open(url)
                        
                        print("safari true")
                    }
                }else {print("error creating link2")}
            }
        
        }
}
struct ToolbarItem: View {
    let iconName: String
    let text: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                Text(text)
                    .font(.caption)
            }
            .padding(.horizontal, 20)
        }
    }
}
struct BottomToolbar: View {
    var body: some View {
        NavigationStack{
            HStack(spacing: 0.2) {
                ToolbarItem(iconName: "person.2", text: "Friends", destination: AnyView(FriendsView()))
                ToolbarItem(iconName: "person.3", text: "Groups", destination: AnyView(GroupView()))
                ToolbarItem(iconName: "bolt", text: "Activities", destination: AnyView(HistoryView()))
                ToolbarItem(iconName: "person.crop.circle", text: "Accounts", destination: AnyView(AccountView()))
            }
            .frame(height: 50)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 3)
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        // Initialize the SFSafariViewController with the provided URL
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Here, you can update the view controller if needed, but it's not required for basic usage.
    }
}

