//
//  SignUpLogInView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct SignUpLogInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var errorMessage: String? = nil
    @State private var isSignUpActive: Bool = false
    @State private var isLogInActive: Bool = false

        
    var body: some View {
        NavigationStack {
            VStack {
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
                
                Button(action: {
                    // Simulating password validation, replace with your validation logic
                    if password == "123" {
                        isLogInActive = true
                        errorMessage = nil // Password is valid, clear error message
                        print("Login successful with username: \(email)")
                    } else {
                        errorMessage = "Invalid username or password. Please try again."
                    }
                }) {
                    Text("Login")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8.0)
                        .padding(.horizontal, 20)
                }
                Button(action: {
                    isSignUpActive = true // Set isSignUpActive to true when button is tapped
                }) {
                    Text("Don't have an account? Sign Up!")
                        .foregroundColor(.blue)
                        .padding()
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 100)
            .navigationDestination(isPresented: $isSignUpActive){
                SignUpView()
            }
            .navigationDestination(isPresented: $isLogInActive){
                HomeView()
            }
        }
    }
}

#Preview {
    SignUpLogInView()
}
