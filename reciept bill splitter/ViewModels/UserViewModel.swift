//
//  UserViewModel.swift
//  reciept bill splitter
//
//  Created by Simon Huang on 2/24/24.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Friend : Codable {
    var username: String
}

struct GroupMember : Codable {
    var username: String
}

struct Group : Codable {
    var groupName: String
    var members: [GroupMember]
    //   var
}

struct Transaction : Codable {
    var itemList: [Item] // Items should not be optional, there should always be an item in a transaction
    var name: String
    
}

struct Item : Codable {
    var priceInCents: Int
    var name: String
    var biddingMembers: [GroupMember]?
    // Todo Add Functions to convert price to string like in HW
}

class UserViewModel : ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    @Published var isLoggedIn = false
    
    @Published var FriendList: [Friend]?
    @Published var GroupList: [Group]?
    
    
    func createUser(email: String, password: String) -> Void {
        print(email, password)
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let result = authResult {
                    print(result)
                    print("Created Account")
                    
                } else {
                    if let x = error {
                        print(x)
                    }
                }
            }
    }
    
    private func setIsLoggedIn() -> Void {
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }
    
    // Creates user in database
    func createUserInDB() async -> Void {
        // Check if User exists
        guard let user = Auth.auth().currentUser else { return }
        
        do {
            try await Firestore.firestore().collection("users").document(user.uid).setData([
                "email": user.email ?? "",
                "userName": "UnNamed",
                "friends": [],
                "groups": [],
                
          ])
          print("Document created")
        } catch {
          print("Error adding document: \(error)")
        }
    }
    
}
