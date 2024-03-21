//
//  SignUpView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var errorMessage: String? = nil

    @Binding var isLoggedIn: Bool
    
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        VStack {
            Text("Sign Up")
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
            }
            
            Button {
                // Simulating password validation, replace with your validation logic
                if password.count >= 6 {
                    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                        guard let result = authResult else {
                            if let x = error { print(x) }
                            return
                        }
                        
                        
                        print(result)
                        print("Created Account")
                        
                        print("Successful login")
                        
                        // Create Database user before loading into home
                        Task {
                            await user.createUserInDB()
                            print("user is true")
                            isLoggedIn = true
                        }
                    }
                    
                } else {
                    errorMessage = "Password should have at least a length of 6"
                }
            } label: {
                Text("Login")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8.0)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 100)
    }
}

#Preview {
    SignUpView(isLoggedIn: .constant(false))
}
