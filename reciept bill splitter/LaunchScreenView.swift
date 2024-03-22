//
//  ContentView.swift
//  reciept bill splitter
//
//  Created by Simon Huang on 2/18/24.
//

import SwiftUI
import FirebaseAuth


struct LaunchScreenView: View {
    @State private var isActive = false //bool variable indicating whether or not to go to
    
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    @State private var isLoggedIn = false
    @EnvironmentObject var router: AppRouter


    @ObservedObject var user = UserViewModel()
    
    var body: some View {
        if isActive {
            NavigationStack {
                if isLoggedIn || router.currentPage == "onboarding" || router.currentPage == "reauth"  {
                    HomeView(isLoggedIn: $isLoggedIn)
                } else {
                    SignUpLogInView(isLoggedIn: $isLoggedIn)
                        .accentColor(.purple) // Match color with logo

                }
            }
            .environmentObject(user)

        } else {
                VStack {
                    VStack{
                        //Displaying Logo
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)) // Gradient circle color
                                .frame(width: 120, height: 120) // Adjust circle size as needed
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2) // Add shadow for depth
                            
                            Image(systemName: "wallet.pass.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.white) // Adjust icon color as needed
                        }

                        
                        //Displaying App Name
                        Text("Wonder Wallet")
                            .font(.system(size: 26))
                            .foregroundColor(.black.opacity(0.80))
                            .fontWeight(.light)
                        
                        // Displaying Slogan
                                Text("Scan, Split, Simplify.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black.opacity(0.60))


                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    
                    //When launching app, slowly fade into displaying logo and app name
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.0)) {
                            self.size = 0.9
                            self.opacity = 1.0
                        }
                    }
                }
                //After logo and app name are fully displayed, initiates transition into ContentView
                .onAppear {
                    if let uid = Auth.auth().currentUser?.uid {
                        isLoggedIn = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                        withAnimation(.easeIn(duration: 0.5)) {
                            self.isActive = true

                        }
                    }
                }
        }
    }
}

#Preview {
    LaunchScreenView()
}
