

import SwiftUI
import StripePaymentSheet
/*struct HomeView: View {
    @State private var isSplitViewActive: Bool = false
    @State private var isViewingGroup = false
    @State private var isJoiningGroup = false
    @State private var isEmptyDisplayFormat = true
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                if isEmptyDisplayFormat {
                    Text("Looks like you aren't in any groups.")
                    Text("Create or Join one.")
                } else {
                    Text("USER IS IN GROUPS PLEASE DISPLAY THEM CODERS.")
                }
                HStack {
                    Spacer()
                    Button {
                        isJoiningGroup = true
                    } label: {
                        Text("+")
                            .frame(width: 60, height: 60)
                            .font(.title2)
                            .foregroundColor(Color.white)
                            .background(Color.black)
                            .clipShape(Circle())
                            .padding()
                    }
                }
                BottomToolbar()
            }
        }
        .onAppear {
            Task {
                await user.getUserData()
                if user.groups.count > 0 {
                    isEmptyDisplayFormat = false
                }
            }
        }
        .navigationDestination(isPresented: $isJoiningGroup) {
            JoinGroupView()
        }
        .navigationDestination(isPresented: $isViewingGroup) {
            GroupView()
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

#Preview {
    HomeView()
        .environmentObject(UserViewModel())
}*/
import SwiftUI

struct HomeView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var isCameraPresented = false
    @State private var isCreatingGroup = false
    @State private var isJoiningGroup = false
    @State private var selectedGroup: Group?
    @State private var isViewingTransaction = false
    @State private var isAlert = false
    
    @StateObject private var paymentManager = PaymentManager()
      @State private var showPaymentSheet = false
    var body: some View {
        NavigationStack {
            VStack {
                if userViewModel.groups.isEmpty {
                    Text("No groups found")
                } else {
                    List(userViewModel.groups, id: \.groupID) { group in
                        NavigationLink(destination: GroupDetailView(selectedGroup: group)) {
                            Text(group.group_name)
                        }
                    }
                }
                Button("Transfer Money") {
                    DatabaseAPI.setCanGetPaid(forUserId: userViewModel.user_id, canGetPaid: true) { error in
                        if let error = error {
                            // Handle the error
                            print("Error setting canGetPaid: \(error.localizedDescription)")
                        } else {
                            // Update was successful
                            print("canGetPaid successfully set for the user")
                        }
                    }

                        //paymentManager.transferMoney(amount: 1000, destinationAccountId: "acct_1Ovoc6QQyo8likZn") // this is the stripeconnectedID destinatin
                                    }
                Button("Collect Payment") {
                        paymentManager.fetchPaymentDataAndPrepareSheet(uid: userViewModel.user_id, amount: 1000)
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
                Button("Check Stripe Balance") {
                    print("Fetching balance")

                    DatabaseAPI.getStripeConnectAccountId(forUserId: userViewModel.user_id) { accountId, error in
                            if let error = error {
                                print("Error retrieving account ID: \(error.localizedDescription)")
                            } else if let accountId = accountId {
                                print("Retrieved Stripe Connect Account ID: \(accountId)")
                                
                                // Use the retrieved account ID to fetch the Stripe balance
                                paymentManager.checkStripeBalance(accountId: accountId) { result in
                                    switch result {
                                    case .success(let balance):
                                        // Here you can update some state to display the balance in your UI
                                        print("Retrieved Stripe balance: \(balance)")
                                    case .failure(let error):
                                        print("Error fetching Stripe balance: \(error.localizedDescription)")
                                    }
                                }
                            } else {
                                print("Stripe Connect Account ID not found")
                            }
                        }
                 
                }


                Button("get paid") {
                        print("creating account")
                    paymentManager.createExpressConnectAccountAndOnboardingLink(email: userViewModel.email)
                }
                Spacer()
                
                if let selectedGroup = selectedGroup {
                    // Here you can integrate the functionality of GroupDetailView
                    Text(selectedGroup.group_name)
                    // Other views and logic from GroupDetailView can be added here
                }
                HStack {
                                   Spacer()
                                   // Circular "+" button
                                   Menu {
                                       Button("Join Group") {
                                           isJoiningGroup = true
                                           print("Join Group tapped")
                                       }
                                       Button("Create Group") {
                                           isCreatingGroup = true
                                       }
                                   } label: {
                                       Image(systemName: "plus.circle.fill")
                                           .resizable()
                                           .frame(width: 50, height: 50)
                                           .foregroundColor(.blue)
                                   }
                                   .navigationDestination(isPresented: $isCreatingGroup) {
                                       CreateGroupView()
                                   }
                                   .navigationDestination(isPresented: $isJoiningGroup) {
                                       JoinGroupView()
                                   }
                               }
                // Bottom toolbar
                BottomToolbar()
                    .environmentObject(paymentManager)
            }
            .navigationTitle("Home")
            .onAppear {
                Task {
                    await userViewModel.getUserData()
                }
            }
        }
        .navigationDestination(isPresented: $isViewingTransaction) {
           // TransactionView(selectedTransactionId: Binding<String>, groupData: <#Binding<Group>#>)
        }
        
    }
    
}

struct BottomToolbar: View {
    @EnvironmentObject var paymentManager: PaymentManager // Ensure this is passed down from the parent view

    var body: some View {
        HStack(spacing: 0.2) {
            ToolbarItem(iconName: "person.2", text: "Friends", destination: AnyView(FriendsView()))
            //ToolbarItem(iconName: "person.3", text: "Home", destination: AnyView(HomeView()))
            ToolbarItem(iconName: "bolt", text: "Activities", destination: AnyView(HistoryView()))
            ToolbarItem(iconName: "person.crop.circle", text: "Accounts", destination: AnyView(AccountView().environmentObject(paymentManager)))
        }
        .frame(height: 50)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct ToolbarItem<Destination: View>: View {
    let iconName: String
    let text: String
    var destination: Destination
    
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
