//
//  GroupView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct GroupView: View {
    @State var selectedGroup: Group?
    
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        VStack {
            Text(selectedGroup?.group_name ?? "None")
            
            
            if (selectedGroup?.owner_id == user.user_id) {
                Button {
                    // Create Transaction Flow / Camera => Picture
                    // => Upload Data to DB => Display
                } label: {
                    Text("Create")
                }
            }

            
            Spacer()
            BottomToolbar()
                .padding()
        }
        .onAppear {
            print("DISPLAYING GROUP \(user.groups[user.selectedGroupIndex])")
            selectedGroup = user.groups[user.selectedGroupIndex]
        }
    }
}

#Preview {
    GroupView()
}
