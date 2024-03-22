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
    /*static func randomString(length: Int) -> String {
     let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
     // WAIT FIX THIS ITS FORCE UNWRAP
     return String((0..<length).map{ _ in letters.randomElement()! })
     }*/
    static func randomString(length: Int) -> String {
        guard length > 0 else { return "" } // Return empty string if length is non-positive
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = (0..<length)
            .map { _ in letters.randomElement() ?? " " } // Use nil-coalescing operator to handle nil values
            .map { String($0) } // Convert characters to strings
            .joined()
        
        return randomString
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
    
    static func createGroup(groupName: String) async -> Void {
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return
        }
        
        do {
            let groupDocument = try await db.collection("groups").addDocument(data: [
                "invite_code": randomString(length: 6),
                "owner_id": user.uid,
                "group_name": groupName,
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
                let members = data["members"] as? [String] ?? []
                print("Member Database API: \(members)")
                
                let invite_code = data["invite_code"] as? String ?? ""
                let owner_id = data["owner_id"] as? String ?? ""
                // Add Transaction Data in future
                
                var groupMemberList: [GroupMember] = []
                for member in members {
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
        guard let _ = Auth.auth().currentUser else {
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
                print(Firebase.FieldValue.serverTimestamp())
                
                try await db.collection("transactions").addDocument(data: [
                    "name": transactionData.name,
                    "items": itemList,
                    "itemBidders": itemBidderDict,
                    "bidderPayments": [:], // USERID To Payment Amount
                    "group_id": groupID,
                    "isCompleted": false,
                    "dateCreated": Firebase.FieldValue.serverTimestamp()
                ])
            }
            
        } catch {
            print("Error creating group: \(error)")
        }
    }
    
    static func grabTransaction(transaction_id: String) async -> Transaction? {
        guard let _ = Auth.auth().currentUser else {
            print("User Does not exist")
            return nil
        }
        
        let transactionRef = db.collection("transactions").document(transaction_id)
        
        do {
            let document = try await transactionRef.getDocument()
            if document.exists {
                let data = document.data()
                // Create Transaction to return if data exists
                if let data = data {
                    // Create Transaction
                    let name = data["name"] as? String ?? ""
                    let items = data["items"] as? [[String : Any]] ?? [[:]]
                    
                    var newItemList: [Item] = []
                    for item in items {
                        let newItem = Item(priceInCents: item["priceInCents"] as? Int ?? 0, name: item["name"] as? String ?? "Unknown Item")
                        newItemList.append(newItem)
                    }
                    let transaction_id = document.documentID
                    let date = data["dateCreated"] as? Timestamp
                    let itemBidders = data["itemBidders"] as? [String:[String]] ?? [:]
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    let newTransaction = Transaction(transaction_id: transaction_id, itemList: newItemList, itemBidders: itemBidders, name: name, isCompleted: isCompleted, dateCreated: date)
                    
                    return newTransaction
                }
            } else {
                return nil
            }
        } catch {
            print("Error finding transactions: \(error)")
        }
        
        return nil
    }
    // Create Transaction Struct List and return
    static func grabAllTransactionsForGroup(groupID: String?) async -> [Transaction]? {
        guard let groupID = groupID else {
            print("GroupID Null")
            return nil
        }
        guard let _ = Auth.auth().currentUser else {
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
                let date = data["dateCreated"] as? Timestamp
                let itemBidders = data["itemBidders"] as? [String:[String]] ?? [:]
                let isCompleted = data["isCompleted"] as? Bool ?? false
                let newTransaction = Transaction(transaction_id: transaction_id, itemList: newItemList, itemBidders: itemBidders, name: name, isCompleted: isCompleted, dateCreated: date)
                
                transactionList.append(newTransaction)
            }
            
            return transactionList
        } catch {
            print("Error finding transactions: \(error)")
        }
        
        return nil
    }
    
    static func assignAllGroupMembersPayment(transaction_id: String) async -> Void {
        guard let _ = Auth.auth().currentUser else {
            print("User Does not exist")
            return
        }
        
        let transactionRef = db.collection("transactions").document(transaction_id)
        // Add New AssignedTransaction for transaction in user
        do {
            let document = try await transactionRef.getDocument()
            
            guard let transactionData = document.data() else {
                return
            }
            
            let groupId = transactionData["group_id"] as? String ?? ""
            let groupRef = db.collection("groups").document(groupId)
            let groupDocument = try await groupRef.getDocument()
            
            guard let groupData = groupDocument.data() else {
                return
            }
            
            let groupMembers = groupData["members"] as? [String] ?? []
            
            // Read document and work
            do {
                // Firestore Transaction to ensure both documents are written together or both fail
                let _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                    // LOOP through transactions and create a new assigned transaction for each user
                    let itemBidders = transactionData["itemBidders"] as? [String:[String]] ?? [:]
                    let items = transactionData["items"] as? [[String : Any]] ?? [[:]]
                    
                    var newItemList: [Item] = []
                    for item in items {
                        let newItem = Item(priceInCents: item["priceInCents"] as? Int ?? 0, name: item["name"] as? String ?? "Unknown Item")
                        newItemList.append(newItem)
                    }
                    
                    // An Abomination of Code
                    for groupMember in groupMembers {
                        let userReference = db.collection("users").document(groupMember)
                        let userDocument: DocumentSnapshot
                        
                        do {
                          try userDocument = transaction.getDocument(userReference)
                        } catch let fetchError as NSError {
                          errorPointer?.pointee = fetchError
                          return nil
                        }

                        var totalCostToPay: Float = 0
                        // Check every item for user
                        for (index, item) in newItemList.enumerated() {
                            // Seach For Member in item bids
                            let currentIndex = String(index)
                            let currentItemBidders = itemBidders[currentIndex] ?? []
                            
                            for userId in currentItemBidders {
                                if userId == groupMember {
                                    // Add Total cost to pay for user
                                    totalCostToPay += Float(item.priceInCents) / Float(currentItemBidders.count)
                                }
                            }
                        }
                        // After Adding cost for user for all items
                        // Create AssignedTransaction for User
                        var assignedTransactionDict: [String:Any] = [:]
                        assignedTransactionDict["transactionName"] = transactionData["name"] as? String ?? ""
                        assignedTransactionDict["associatedTransaction_id"] = transaction_id
                        assignedTransactionDict["user_idToPay"] = groupData["owner_id"] as? String ?? ""
                        assignedTransactionDict["isPaid"] = false
                        assignedTransactionDict["ammountToPay"] = totalCostToPay
                        
                        transaction.updateData(["assignedTransaction.\(transaction_id)": assignedTransactionDict], forDocument: userReference)
                    }
                    print("FINISHED")
                    return nil
                })
                
                return
            } catch {
                // Handle error during transaction
                print("Error Assigning Transaction: \(error)")
                return
            }
                
        } catch let error {
            print("Error updating transaction: \(error)")
        }

        
    }
    
    static func retrieveStripeCustomerId(uid: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        let customerRef = db.collection("customers").document(uid)
        
        customerRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let stripeCustomerId = data?["stripeId"] as? String
                completion(stripeCustomerId)
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    static func setCanGetPaid(forUserId userId: String, canGetPaid: Bool, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("customers").document(userId)
        
        userRef.updateData(["canGetPaid": canGetPaid]) { error in
            if let error = error {
                print("Error updating canGetPaid: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Successfully updated canGetPaid to \(canGetPaid) for user \(userId)")
                completion(nil)
            }
        }
    }
    static func getStripeConnectAccountId(completion: @escaping (String?, Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("User does not exist")
            completion(nil, NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required"]))
            return
        }
        let userRef = db.collection("customers").document(user.uid)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error retrieving Stripe Connect Account ID: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            guard let document = document, document.exists else {
                print("Document does not exist")
                completion(nil, NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"]))
                return
            }
            let accountId = document.data()?["stripeConnectAccountId"] as? String
            completion(accountId, nil)
        }
    }
    static func getStripeConnectAccountId(forUserId userId: String, completion: @escaping (String?, Error?) -> Void) {
        let userRef = Firestore.firestore().collection("customers").document(userId)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error retrieving Stripe Connect Account ID: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            guard let document = document, document.exists else {
                print("Document does not exist")
                completion(nil, NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"]))
                return
            }

            if let stripeConnectAccountId = document.data()?["stripeConnectAccountId"] as? String {
                print("Retrieved Stripe Connect Account ID: \(stripeConnectAccountId)")
                completion(stripeConnectAccountId, nil)
            } else {
                print("Stripe Connect Account ID not found in the document")
                completion(nil, nil)
            }
        }
    }


    static func fetchUsernames(for documentIDs: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        let userCollection = db.collection("users")
        
        // Create a dispatch group to synchronize asynchronous operations
        let dispatchGroup = DispatchGroup()
        
        var usernames: [String] = []
        var errors: [Error] = []
        
        for documentID in documentIDs {
            dispatchGroup.enter()
            
            userCollection.document(documentID).getDocument { documentSnapshot, error in
                defer {
                    dispatchGroup.leave()
                }
                
                if let error = error {
                    errors.append(error)
                    return
                }
                
                if let username = documentSnapshot?.get("userName") as? String {
                    usernames.append(username)
                }
            }
        }
        
        // Notify the completion handler when all fetch operations are completed
        dispatchGroup.notify(queue: .main) {
            if !errors.isEmpty {
                // If there were errors during fetch, pass the first error to the completion handler
                completion(.failure(errors[0]))
            } else {
                // Otherwise, pass the fetched usernames to the completion handler
                completion(.success(usernames))
            }
        }
    }



    static func canUserGetPaid(uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("customers").document(uid)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let canGetPaid = document.data()?["canGetPaid"] as? Bool ?? false
                completion(canGetPaid)
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    static func setStripeConnectAccountId(accountId: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("User Does not exist")
            return
        }
        let userRef = db.collection("customers").document(user.uid)
        
        // Update the user document with the Stripe Connect Account ID
        userRef.updateData(["stripeConnectAccountId": accountId]) { error in
            if let error = error {
                print("Error setting Stripe Connect Account ID: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Stripe Connect Account ID set successfully.")
                completion(nil)
            }
        }
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
    
