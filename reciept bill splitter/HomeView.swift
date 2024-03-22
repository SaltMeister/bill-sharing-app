
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

                Button("Create Group") {
                    if userViewModel.canGetPaid {
                        isCreatingGroup = true
                    } else {
                        showInfoAlert = true
                    }
                }
                .foregroundColor(userViewModel.canGetPaid ? .primary : .red)
                .navigationDestination(isPresented: $isCreatingGroup) {
                    CreateGroupView()
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
        .environmentObject(userViewModel)
    }

    private func listenToTransactionsForGroup(groupId: String) {
        let db = Firestore.firestore()
        db.collection("transactions").whereField("group_id", isEqualTo: groupId)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshots = querySnapshot else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                
                if let error = error {
                    print("Error retreiving collection: \(error)")
                }
                
                // Find Changes where document is a diff
                snapshots.documentChanges.forEach { diff in
                    if diff.type == .modified {
                        // Check if the proper field is adjusted
                        print("GROUP TRANSACTION HAS BEEN MODIFIED")
                        let data = diff.document.data()
                        let isTransactionCompleted = data["isCompleted"] as? Bool ?? false
                        
                        if isTransactionCompleted {
                            
                        }
                        // Assign Each Member Their Parts to Pay
                    }
                    else if diff.type == .added {
                        print("NEW TRANSACTION CREATED FOR GROUP")
                    }
                }
            }
    }
    private func assignUsersTransaction() {
        Task{
            await userViewModel.getUserData()
            await userViewModel.updateCanGetPaidStatus()
        }
        
    }
}

    



struct BottomToolbar: View {
    @Binding var isLoggedIn: Bool // Receive isLoggedIn as a binding

    @EnvironmentObject var paymentManager: PaymentManager // Ensure this is passed down from the parent view

    var body: some View {
        HStack(spacing: 0.2) {
            ToolbarItem(iconName: "bolt", text: "Activities", destination: AnyView(HistoryView()))
            ToolbarItem(iconName: "person.crop.circle", text: "Account", destination: AnyView(AccountView(isLoggedIn: $isLoggedIn).environmentObject(paymentManager)))
        }
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                )
        )
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
