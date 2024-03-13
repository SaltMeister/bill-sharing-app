//
//  HomeView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct HomeView: View {
    @State private var isSplitViewActive : Bool = false
    @State private var isViewingGroup = false
    
    @State private var isJoiningGroup = false
    
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
                }
                else {
                    // Display all groups
                    ForEach(Array(user.groups.enumerated()), id: \.offset) { index, element in
                        HStack {
                            Text(element.group_name)
                            Text("Invite Code \(element.invite_code)")
                        }
                        .padding(.vertical)
                        .shadow(color: .gray, radius: 0.5)
                        .onTapGesture {
                            user.selectedGroupIndex = index
                            isViewingGroup = true
                            // Open Group View and display group data
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
}
