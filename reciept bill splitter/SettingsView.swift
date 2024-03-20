//
//  SettingsView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct SettingsView: View {
    @State private var isEditing = false
    @State private var newUsername = ""
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        VStack {
            HStack {
                if isEditing {
                    TextField("Enter new username", text: $newUsername)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text("Current Username: " + newUsername)
                        .padding()
                }
                Button(action: {
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(isEditing ? .green : .blue)
                }
            }
            
            if isEditing {
                Button("Save") {
                    Task {
                        await user.createUserInDB(username: newUsername)
                        isEditing.toggle()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
    }
}
