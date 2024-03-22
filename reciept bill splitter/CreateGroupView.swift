//
//  CreateGroupView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 3/17/24.
//

import SwiftUI

struct CreateGroupView: View {
    
    @EnvironmentObject var user: UserViewModel
    @State var groupName = "Default Name"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("Enter Group Name", text: $groupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button {
                Task {
                    await DatabaseAPI.createGroup(groupName: groupName)
                    await user.getUserData()
                    dismiss()
                }
            } label: { Text("Create Group") }
                .font(.custom("Avenir", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.black)
                .cornerRadius(15)
        }
        }
    }

#Preview {
    CreateGroupView()
}
