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
                Text("Wonder Wallet")
                    .font(.system(size: 30))
                    .foregroundColor(.black.opacity(0.80))
                    .fontWeight(.light)
                    .padding()
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80) // Adjust circle size as needed
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2) // Adjust shadow radius as needed
                    
                    Image(systemName: "wallet.pass.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50) // Adjust icon size as needed
                        .foregroundColor(.white) // Adjust icon color as needed
                }
                .frame(width: 100, height: 100) // Adjust total size of the icon
                .padding()

                
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
                        .font(.headline)
                        .foregroundColor(.white) // Set text color to white
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)) // Use gradient background
                        .cornerRadius(8) // Round the corners of the button
                        .padding(.horizontal) // Add horizontal padding
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
            .navigationDestination(isPresented: $isLoggedIn){
                HomeView(isLoggedIn: $isLoggedIn)
            }
        }
    }
    
    
}
#Preview {
    SignUpLogInView(isLoggedIn: .constant(false))
}
