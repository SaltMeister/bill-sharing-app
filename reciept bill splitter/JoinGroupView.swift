//
//  JoinGroupView.swift
//  reciept bill splitter
//
//  Created by Simon Huang on 3/12/24.
//

import SwiftUI

struct JoinGroupView: View {
    @State private var inviteCode = ""
    
    @EnvironmentObject var user: UserViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("Enter Invite Code", text: $inviteCode)
                               .padding()
                               .background(Color(UIColor.systemBackground))
                               .cornerRadius(10)
                               .font(.largeTitle)
                               .padding(.horizontal)
                               .textFieldStyle(.roundedBorder)
                           
                           Button {
                               Task {
                                   if !inviteCode.isEmpty {
                                       // Call the joinGroup method with the invite code
                                       let result = await DatabaseAPI.joinGroup(groupJoinId: inviteCode)
                                       
                                       if case .failure = result {
                                            print("COULD COULD NOT JOIN GROUP")
                                            return
                                       }
                                       // Refresh user data after joining the group
                                       await user.getUserData()
                                       
                                       dismiss()
                                   } else {
                                       // Handle case where invite code is empty
                                       print("Invite code is empty")
                                   }
                               }
                           } label: { Text("Join Group") }
                               .font(.custom("Avenir", size: 30))
                               .foregroundColor(.white)
                               .padding(.horizontal, 20)
                               .padding(.vertical, 10)
                               .background(Color.black)
                               .cornerRadius(15)
        }
    }
}

#Preview {
    JoinGroupView()
}
