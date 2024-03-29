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
    var id: String
}

struct Group : Codable {
    var groupID: String
    var group_name: String
    var members: [GroupMember]
    var invite_code: String
    var owner_id: String
    var transactions: [String] // Fix Later
    //   var
}

struct Transaction : Codable {
    var transaction_id: String
    var itemList: [Item] // Items should not be optional, there should always be an item in a transaction
    var itemBidders: [String:[String]]
    var name: String
    var isCompleted: Bool
    var dateCreated: Timestamp?
}

struct AssignedTransaction : Codable {
    var transactionName: String
    var associatedTransaction_id: String
    var user_idToPay: String
    var isPaid: Bool
    var amountToPay: Int
    
}

struct User : Codable {
    var email: String
    var userName: String
    var groups: [String]?
    var friends: [String]?
    var completedTransactions: [String]?
}

struct Item : Codable {
    var priceInCents: Int
    var name: String
    // Todo Add Functions to convert price to string like in HW
}

class UserViewModel : ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var user_id = ""
    @Published var username = ""
    @Published var canGetPaid = false

    @Published var groups: [Group] = []

    @Published var groups_id: [String]?
    @Published var friends: [String]?
    @Published var completedTransactions: [String]?
    
    @Published var currentSelectedGroupTransactions: [Transaction] = []
    @Published var selectedTransaction: Transaction?
    
    // Initialize Env Variable Data
    func getUserData() async -> Void {
        let userData = await DatabaseAPI.grabUserData()
        
        guard let userData = userData else { return }
        
        DispatchQueue.main.async {
            self.email = userData.email
            self.groups_id = userData.groups
            self.friends = userData.friends
            self.completedTransactions = userData.completedTransactions
            self.user_id = Auth.auth().currentUser?.uid ?? ""
            self.username = userData.userName
        }
        
        await setUserGroupData()
    }
    
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
                "userName": "Unnamed",
                "friends": [], // reference document  id of other users uid
                "groups": [], // group collection document ids

                "assignedTransaction": [:]
          ])
          print("Document created")
            
            
        } catch {
          print("Error adding document: \(error)")
        }
    }
    func updateUserName(newName: String) async -> Void {
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return
        }
        do {
            try await Firestore.firestore().collection("users").document(user.uid).updateData([
                "userName": newName
          ])
          print("Document created")
            
            
        } catch {
          print("Error adding document: \(error)")
        }
    }
    
    
    // Set Env Variable Group Data for use called in GetUserData()
    private func setUserGroupData() async -> Void {
        let data = await DatabaseAPI.getGroupData()
        
        if let groupData = data {
            DispatchQueue.main.async {
                print("Updated GRoups")
                self.groups = groupData
            }
        }
         
    }
    func updateCanGetPaidStatus() async {
         guard let uid = Auth.auth().currentUser?.uid else {
             print("User is not signed in")
             return
         }

         DatabaseAPI.canUserGetPaid(uid: uid) { canGetPaid in
             DispatchQueue.main.async {
                 self.canGetPaid = canGetPaid
             }
         }
     }
}
