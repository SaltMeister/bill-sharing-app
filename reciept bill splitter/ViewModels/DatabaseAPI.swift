//
//  DatabaseAPI.swift
//  reciept bill splitter
//
//  Created by Simon Huang on 2/29/24.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase
class DatabaseAPI {
    static var db = Firestore.firestore()
    
    // https://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        // WAIT FIX THIS ITS FORCE UNWRAP
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    static func grabUserData() async -> User? {
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return nil
        }
        
        do {
            let userRef = db.collection("users").document(user.uid)
            
            let document =  try await userRef.getDocument()
            
            if document.exists {
                
                let result = try document.data(as: User.self)
                
                print("FOUND USER")
                print(result)
                
                return result
            }
        } catch {
            print("Error finding User: \(error)")
        }
        
        return nil
    }
    
    static func createGroup() async -> Void {
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return
        }
        
        do {
            let groupDocument = try await db.collection("groups").addDocument(data: [
                "invite_code": randomString(length: 6),
                "owner_id": user.uid,
                "group_name": "unnamedGroup",
                "transactions": [],
                "members": [user.uid]
            ])
            
            
            print("Group created")
            
            let docRef = db.collection("users").document(user.uid)
            let document = try await docRef.getDocument()
            
            if document.exists {
                // Update Document of User
                try await docRef.updateData([
                    "groups": FieldValue.arrayUnion([groupDocument.documentID])
                ])
            } else {
                print("User Does Not exist")
            }
            
        } catch {
            print("Error creating group: \(error)")
        }
    }
    static func joinGroup(groupJoinId: String) async -> Result<Void, Error> {
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return .failure(NSError(domain: "UserDoesNotExist", code: 0, userInfo: nil))
        }
        
        let groupRef = db.collection("groups").whereField("invite_code", isEqualTo: groupJoinId)
        let userRef = db.collection("users").document(user.uid)
        
        var groupDocumentId = ""
        
        do {
            let queryResult = try await groupRef.getDocuments()
            guard let document = queryResult.documents.first else {
                // Handle case where no group matches the invite code
                print("No group found with the provided invite code")
                return .failure(NSError(domain: "GroupNotFound", code: 0, userInfo: nil))
            }
            groupDocumentId = document.documentID
        } catch {
            // Handle error while querying groups
            print("Error querying groups: \(error)")
            return .failure(error)
        }
        
        let docRef = db.collection("groups").document(groupDocumentId)
        
        do {
            // Firestore Transaction to ensure both documents are written together or both fail
            let _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                
                let gDoc: DocumentSnapshot
                do {
                    try gDoc = transaction.getDocument(docRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                // Add user id to group members
                transaction.updateData(["members": FieldValue.arrayUnion([user.uid])], forDocument: gDoc.reference)
                // Add group id to user groups
                transaction.updateData(["groups": FieldValue.arrayUnion([gDoc.documentID])], forDocument: userRef)
                print("Success Join Group Transaction")
                return nil
            })
            
            return .success(())
        } catch {
            // Handle error during transaction
            print("Error joining group: \(error)")
            return .failure(error)
        }
    }

    
    
    // Grabs user group data from database
    static func getGroupData() async -> [Group]? {
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return nil
        }
        
        do {
            
            let querySnapshots = db.collection("groups").whereField("members", arrayContains: user.uid)
            
            let documents = try await querySnapshots.getDocuments()
            
            var foundGroups: [Group] = []
            
            print("Trying to find document")
            for document in documents.documents {
                
                let data = document.data()
                
                let groupID = document.documentID
                let group_name = data["group_name"] as? String ?? ""
                let members = data["members"] as? [Int:String] ?? [:]
                
                let invite_code = data["invite_code"] as? String ?? ""
                let owner_id = data["owner_id"] as? String ?? ""
                // Add Transaction Data in future
                
                var groupMemberList: [GroupMember] = []
                for (index, member) in members {
                    groupMemberList.append(GroupMember(id: member))
                }
                
                let newGroup = Group(groupID: groupID, group_name: group_name, members: groupMemberList, invite_code: invite_code, owner_id: owner_id, transactions: [])
                
                foundGroups.append(newGroup)
            }
            print(foundGroups)
            return foundGroups
            
        } catch {
            print("Error finding User: \(error)")
        }
        
        return nil
    }
    
    // Provided a transaction and create data for transaction
    static func createTransaction(transactionData: Transaction, groupID: String?) async -> Void {
        guard let groupID = groupID else {
            print("GroupID Null")
            return
        }
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return
        }
        
        
        let groupRef = db.collection("groups").document(groupID)
        
        // Create Transaction Document in collection and relate it to group document
        do {
            let groupDocument = try await groupRef.getDocument()
            
            if groupDocument.exists {
                let data = groupDocument.data()
                let members = data?["members"] as? [String] ?? []
                
                // Create transaction document and add group members to item bidders
                var itemBidderDict: [String: [String]] = [:]
                var itemList = [[String : Any]]()
                
                for i in 0..<transactionData.itemList.count {
                    itemBidderDict.updateValue(members, forKey: String(i))
                    itemList.append([
                        "priceInCents" : transactionData.itemList[i].priceInCents,
                        "name": transactionData.itemList[i].name
                    ])
                }
            
                try await db.collection("transactions").addDocument(data: [
                    "name": transactionData.name,
                    "items": itemList,
                    "itemBidders": itemBidderDict,
                    "group_id": groupID,
                    "isCompleted": false  // New boolean field with default value
                ])
            }
            
        } catch {
            print("Error creating group: \(error)")
        }
    }
    // Create Transaction Struct List and return
    static func grabAllTransactionsForGroup(groupID: String?) async -> [Transaction]? {
        guard let groupID = groupID else {
            print("GroupID Null")
            return nil
        }
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return nil
        }
        
        var transactionList: [Transaction] = []
        
        do {
            let transactionQuery = db.collection("transactions").whereField("group_id", isEqualTo: groupID)
            
            
            let documents = try await transactionQuery.getDocuments()
            
            for document in documents.documents {
                let data = document.data()
                // Create Transaction
                let name = data["name"] as? String ?? ""
                let items = data["items"] as? [[String : Any]] ?? [[:]]
                
                var newItemList: [Item] = []
                for item in items {
                    let newItem = Item(priceInCents: item["priceInCents"] as? Int ?? 0, name: item["name"] as? String ?? "Unknown Item")
                    newItemList.append(newItem)
                }
                let transaction_id = document.documentID
                
                let itemBidders = data["itemBidders"] as? [String:[String]] ?? [:]
                let isCompleted = data["isCompleted"] as? Bool ?? false
                
                let newTransaction = Transaction(transaction_id: transaction_id, itemList: newItemList, itemBidders: itemBidders, name: name, isCompleted: isCompleted)
                
                transactionList.append(newTransaction)
            }
            
            return transactionList
        } catch {
            print("Error finding transactions: \(error)")
        }
        
        return nil
    }
    static func toggleGroupTransactionsCompletion(transactionID: String, completion: Bool) async {
        let transactionRef = db.collection("transactions").document(transactionID)
        
        do {
            let document = try await transactionRef.getDocument()
            if document.exists {
                try await transactionRef.updateData([
                    "isCompleted": completion
                ])
            }
            print("Transaction \(transactionID) updated to completion status \(completion).")
        } catch let error {
            print("Error updating transaction: \(error)")
        }
    }

}
