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
    
    @Published var friendList: [Friend]?
    @Published var groupList: [Group]?
    //@Published var transactionList: [Trans]
    
    // Creates user in database
    func createUserInDB() async -> Void {
        // Check if User exists
        guard let user = Auth.auth().currentUser else { 
            print("User Does not exist")
            return
        }
        
        do {
            try await Firestore.firestore().collection("users").document(user.uid).setData([
                "email": user.email ?? "",
                "userName": "UnNamed",
                "friends": [], // reference document  id of other users uid
                "groups": [], // group collection document ids
                "completedTransactions": [], // History of completed user transactions
//                "activeRequests": []
          ])
          print("Document created")
            
            
        } catch {
          print("Error adding document: \(error)")
        }
    }
    
}
