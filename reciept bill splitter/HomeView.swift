//
//  HomeView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: UserViewModel
    @State private var isSplitViewActive : Bool = false
    @State private var isJoinGroupViewActive : Bool = false
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                Button(action: {
                    isSplitViewActive = true
                }){
                    Text("Split")
                        .font(.custom("Avenir", size: 30))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.black)
                        .cornerRadius(1)
                        
                }
                Button(action: {
                    isJoinGroupViewActive = true
                }){
                    Text("Enter Group Code")
                        .font(.custom("Avenir", size: 30))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.black)
                        .cornerRadius(1)
                        
                }
                Spacer()
                BottomToolbar()
                    .padding()
            }
        }
        .navigationDestination(isPresented: $isSplitViewActive){
            SplitView()
        }
        .navigationDestination(isPresented: $isJoinGroupViewActive){
            JoinGroupView()
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
                    .foregroundColor(.black)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
        }
    }
}
