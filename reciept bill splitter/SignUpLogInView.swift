//
//  SignUpLogInView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFunctions

struct SignUpLogInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var errorMessage: String? = nil
    @State private var isSignUpActive: Bool = false
    
    @Binding var isLoggedIn: Bool
    
    @EnvironmentObject var user: UserViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Log In")
                
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
                        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                            //                          guard let strongSelf = self else { return }
                            
                            guard let result = authResult else {
                                if let x = error {
                                    print(x)
                                    print("Failed to Sign in")
                                    errorMessage = "Failed to Sign In"
                                }
                                return
                            }
                            
                            print(result)
                            print("Signed In Account")
                            
                            let user = Auth.auth().currentUser
                            if let user = user {
                                let uid = user.uid
                                let email = user.email ?? ""
                                print(uid)
                                print(email)
                            }
                           


                            print("Successful login")
                                isLoggedIn = true
                                dismiss()
                     
                        }
                        
                        //                        errorMessage = nil // Password is valid, clear error message
                        //                        print("Login successful with username: \(email)")
                    } else {
                        errorMessage = "Invalid username or password. Please try again."
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
                
                Button {
                    isSignUpActive = true // Set isSignUpActive to true when button is tapped
                } label: {
                    Text("Don't have an account? Sign Up!")
                        .foregroundColor(.blue)
                        .padding()
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 100)
            .navigationDestination(isPresented: $isSignUpActive){
                SignUpView(isLoggedIn: $isLoggedIn)
            }
        }
    }
    
    
}
#Preview {
    SignUpLogInView(isLoggedIn: .constant(false))
}
