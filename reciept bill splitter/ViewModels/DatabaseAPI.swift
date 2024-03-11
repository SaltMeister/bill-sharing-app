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
    static func grabUserData() async ->  User? {
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
            
            let querySnapshots = db.collection("groups").whereField("owner_id", isEqualTo: user.uid)
            
            let documents = try await querySnapshots.getDocuments()
            
            var foundGroups: [Group] = []
            
            print("Trying to find document")
            for document in documents.documents {
                
                let data = document.data()
                
                let groupID = document.documentID
                let group_name = data["group_name"] as? String ?? ""
                let members = data["members"] as? [String] ?? []
                
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
}
