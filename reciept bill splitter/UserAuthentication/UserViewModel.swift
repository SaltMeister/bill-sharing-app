//
//  UserViewModel.swift
//  reciept bill splitter
//
//  Created by Simon Huang on 2/24/24.
//

import Foundation
import SwiftUI
import FirebaseAuth

class UserViewModel : ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    
    
    func createUser(email: String, password: String) -> Bool {
        print(email, password)
        
        @State var isSuccess = false
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let result = authResult {
                print(result)
                print("Created Account")
                isSuccess = true
            } else {
                if let x = error {
                    print(x)
                    print("Failed")
                }
            }
        }
        
        
        return isSuccess
    }
    
    func login(email: String, password: String) -> Bool {
        print(email, password)
        
        @State var isSuccess = false
        // Handle Completion of signing function with completion function parameter
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
          guard let strongSelf = self else { return }
            if let result = authResult {
//                print(result.user.uid, result.user.email)
                print("Signed In Account")
                isSuccess = true
            } else {
                if let x = error {
                    print(x)
                    print("Failed to Sign in")
                }
            }
        }
        
        return isSuccess
    }
}
