//
//  ContentView.swift
//  reciept bill splitter
//
//  Created by Simon Huang on 2/18/24.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false //bool variable indicating whether or not to go to ContentView
    @State private var size = 0.8
    @State private var opacity = 0.5
    var body: some View {
        if isActive {
            SignUpLogInView()
        } else {
                VStack {
                    VStack{
                        //Displaying Logo
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                        
                        //Displaying App Name
                        Text("Bill Split")
                            .font(Font.custom("Baskerille-Bold", size: 26))
                            .foregroundColor(.black.opacity(0.80))
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
