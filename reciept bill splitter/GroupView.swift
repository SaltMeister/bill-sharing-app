//
//  GroupView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

/*import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct GroupView: View {
    @EnvironmentObject var user: UserViewModel
    @State private var isCameraPresented = false
    @State private var selectedGroup: Group?
    
    var body: some View {
        NavigationView {
            VStack {
                if user.groups.isEmpty {
                    Text("No groups found")
                } else {
                    List(user.groups, id: \.groupID) { group in
                        NavigationLink(destination: GroupDetailView(selectedGroup: group)) {
                            Text(group.group_name)
                        }
                    }
                }
            }
            .navigationTitle("Your Groups")
            .onAppear {
                Task {
                    await user.getUserData()
                }
            }
        }
    }
}*/




