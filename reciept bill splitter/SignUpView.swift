//
//  SignUpView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct SignUpView: View {
    var body: some View {
<<<<<<< Updated upstream
        Text("Sign Up View")
=======
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
                    let didCreateAccount = user.createUser(email: email, password: password)
                    
                    // todo log in to user after account is created
                    // CouldFirebase create account
                    if didCreateAccount {
                        errorMessage = "Success"
                        isLoggedIn = true
                    }
                    
                }
                else {
                    errorMessage = "Password should have at least a length of 6"
                }
            } label: {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8.0)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 100)
>>>>>>> Stashed changes
    }
}

#Preview {
    SignUpView()
}
