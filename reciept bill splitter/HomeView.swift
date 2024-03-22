
import SwiftUI
import Firebase
import StripePaymentSheet

struct HomeView: View {
    @State private var isSplitViewActive = false
    @State private var isViewingGroup = false
    @State private var isJoiningGroup = false
    @State private var isEmptyDisplayFormat = true
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var isCreatingGroup = false
    @State private var selectedGroup: Group?
    @State private var isAlert = false
    @State private var showInfoAlert = false
    
    @StateObject private var paymentManager = PaymentManager()
    @State private var showPaymentSheet = false

    @Binding var isLoggedIn: Bool
    var body: some View {
        NavigationStack {
            VStack {
                if userViewModel.groups.isEmpty {
                    Text("No groups found")
                } else {
                    List(userViewModel.groups, id: \.groupID) { group in
                        NavigationLink(destination: GroupDetailView(selectedGroup: group)) {
                            VStack(alignment: .leading) {
                                Text(group.group_name)
                                Text("Invite Code: \(group.invite_code)")
                            }
                            .onAppear {
                                Task {
                                    listenToTransactionsForGroup(groupId: group.groupID)
                                }
                            }
                        }
                    }
                }

                Spacer()

                Button("Transfer Money") {
                    paymentManager.transferMoney(amount: 1000, destinationAccountId: "acct_1Ovoc6QQyo8likZn")
                }

                Button("Collect Payment") {
                    paymentManager.fetchPaymentDataAndPrepareSheet(uid: userViewModel.user_id, amount: 1000)
                }

                VStack {
                    if let paymentSheet = paymentManager.paymentSheet {
                        PaymentSheet.PaymentButton(paymentSheet: paymentSheet, onCompletion: paymentManager.onPaymentCompletion) {
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

                Menu {
                    Button("Create Group") {
                            if userViewModel.canGetPaid {
                                isCreatingGroup = true
                            } else {
                                showInfoAlert = true
                            }
                        }.foregroundColor(userViewModel.canGetPaid ? .white : .red) // Text color changes based on `canGetPaid`       
                        Button("Join Group") {
                            isJoiningGroup = true
                            print("Join Group tapped")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        
                    }
                }

                .navigationDestination(isPresented: $isCreatingGroup) {
                    CreateGroupView()
                }
                .navigationDestination(isPresented: $isJoiningGroup) {
                    JoinGroupView()
                }
                BottomToolbar(isLoggedIn: $isLoggedIn).environmentObject(paymentManager)
            }
            .navigationTitle("Home")
            .alert(isPresented: $showInfoAlert) {
                Alert(
                    title: Text("Action Required"),
                    message: Text("You need to complete your payment setup to create a group."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                Task {
                    await userViewModel.getUserData()
                }
            }
        }
    private func assignUsersTransaction() {
        Task{
            await userViewModel.getUserData()
            await userViewModel.updateCanGetPaidStatus()
        }
    }

private func listenToTransactionsForGroup(groupId: String) {
        let db = Firestore.firestore()
        db.collection("transactions").whereField("group_id", isEqualTo: groupId)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshots = querySnapshot else {
                    print("Error fetching documents: (error!)")
                    return
                }

                if let error = error {
                    print("Error retreiving collection: (error)")
                }
                // Find Changes where document is a diff
                snapshots.documentChanges.forEach { diff in
                    if diff.type == .modified {
                        // Check if the proper field is adjusted
                        print("GROUP TRANSACTION HAS BEEN MODIFIED")
                        let data = diff.document.data()
                        let isTransactionCompleted = data["isCompleted"] as? Bool ?? false

                        if isTransactionCompleted {
                            print("ASSINING PAYMENTRS")
                            Task {
                                await DatabaseAPI.assignAllGroupMembersPayment(transaction_id: diff.document.documentID)
                            }
                        }
                        // Assign Each Member Their Parts to Pay
                    }
                    else if diff.type == .added {
                        print("NEW TRANSACTION CREATED FOR GROUP")
                    }
                }
            }
    }
  
        
    }


    



struct BottomToolbar: View {
    @EnvironmentObject var paymentManager: PaymentManager // Ensure this is passed down from the parent view

    
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        HStack(spacing: 0.2) {
            ToolbarItem(iconName: "person.2", text: "Friends", destination: AnyView(FriendsView()))
            //ToolbarItem(iconName: "person.3", text: "Home", destination: AnyView(HomeView()))
            ToolbarItem(iconName: "bolt", text: "Activate Transactions", destination: AnyView(AllAssignedTransactions()))
            ToolbarItem(iconName: "person.crop.circle", text: "Accounts", destination: AnyView(AccountView(isLoggedIn: $isLoggedIn).environmentObject(paymentManager)))
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
