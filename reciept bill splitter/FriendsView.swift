//
//  FriendsView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct FriendsView: View {
    @State private var isAddFriendsActive : Bool = false
    @State private var searchText: String = ""
    @State private var friends: [(String, String)] = [
        ("John", "john_doe"),
        ("Jane", "jane_smith"),
        ("Alice", "alice_wonder"),
        ("Bob", "bob_jones"),
        ("Emily", "emily_green"),
        ("Michael", "michael_brown"),
    ]
    
    var body: some View {
        NavigationStack{
            VStack {
                TextField("Search", text: $searchText)
                    .autocapitalization(.none) // Disable automatic capitalization
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                //List(friends.filter({ searchText.isEmpty ? true : $0.0.contains(searchText) }), id: \.0) { friend, username in
                List(friends.filter({ searchText.isEmpty ? true : $0.0.contains(searchText) || $0.1.contains(searchText) }), id: \.0) { friend, username in
                    HStack {
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(friend)
                                .font(.headline)
                            Text("\(username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Button(action: {
                    isAddFriendsActive = true // Set isSignUpActive to true when button is tapped
                }) {
                    Text("Add Friends")
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                }
                Rectangle()
                               .foregroundColor(Color(.systemGray6))
                               .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height/15)
            }
            .navigationTitle("Friends")
            .navigationDestination(isPresented: $isAddFriendsActive){
                AddFriendView()
            }
        }
    }
}

#Preview {
    FriendsView()
}
