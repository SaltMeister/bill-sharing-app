
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct HomeView: View {
    let db = Firestore.firestore()
    
    @StateObject private var userViewModel = UserViewModel()
    @State private var isCameraPresented = false
    @State private var isCreatingGroup = false
    @State private var isJoiningGroup = false
    @State private var selectedGroup: Group?
    @State private var isViewingTransaction = false
    @State private var isAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if userViewModel.groups.isEmpty {
                    Text("No groups found")
                } else {
                    List(userViewModel.groups, id: \.groupID) { group in
                        NavigationLink(destination: GroupDetailView(selectedGroup: group)) {
                            Text(group.group_name)
                            Text(group.groupID)              
                        }

                        .onAppear {
                            Task {
                                listenToTransactionsForGroup(groupId: group.groupID)
                            }
                        }
                    }
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
            }
            .navigationTitle("Home")
            .onAppear {
                Task {
                    await userViewModel.getUserData()
                }
            }
        }
    }
    
    private func listenToTransactionsForGroup(groupId: String) {
        print("LISTENING TO DOCUMENTS")
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
//                        let data = diff.document.data()
//                        let isTransactionCompleted = data["isCompleted"] as? Bool ?? false
//                        print(isTransactionCompleted)
//                        
//                        // Alert if modified document is true
//                        if isTransactionCompleted {
//                            isAlert = true
                       // }
                    }
                    else if diff.type == .added {
                        print("NEW TRANSACTION CREATED FOR GROUP")
                        // Update Transaction List append
//                        Task {
//                            if let transactions = await DatabaseAPI.grabAllTransactionsForGroup(groupID: selectedGroup?.groupID) {
//                                DispatchQueue.main.async {
//                                    user.currentSelectedGroupTransactions = transactions // Store all transactions
//                                    totalSpent = transactions.map { transaction in
//                                        transaction.itemList.map { Double($0.priceInCents) / 100 }.reduce(0, +)
//                                    }.reduce(0, +)
//                                }
//                            } else {
//                                print("No transactions found for group \(selectedGroup?.groupID ?? "")")
//                            }
                        //}
                    }
                }
            }
    }
    
}

struct BottomToolbar: View {
    var body: some View {
        HStack(spacing: 0.2) {
            ToolbarItem(iconName: "person.2", text: "Friends", destination: AnyView(FriendsView()))
            //ToolbarItem(iconName: "person.3", text: "Home", destination: AnyView(HomeView()))
            ToolbarItem(iconName: "bolt", text: "Activities", destination: AnyView(HistoryView()))
            ToolbarItem(iconName: "person.crop.circle", text: "Accounts", destination: AnyView(AccountView()))
        }
        .frame(height: 50)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
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

