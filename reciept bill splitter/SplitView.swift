//
//  SplitView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct SplitView: View {
    @State private var isCameraActive: Bool = false // State to control camera view
    @State private var isBillViewActive: Bool = false //

    var body: some View {
        VStack{
            NavigationStack{
                Text("Group Code: ABC123")
                    .font(.custom("Avenir", size: 30))
                    .foregroundColor(.black)
                    .padding()
               
                Button(action: {
                    isCameraActive = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                        .clipShape(Circle()) // Clip to circle shape
                }
                .padding(.bottom, 5)
                
                Text("Scan Receipt")
                    .font(.custom("Avenir", size: 15))
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                
                Text("or")
                    .font(.custom("Avenir", size: 10))
                    .foregroundColor(.black)
                    .padding()
                
                
                Button(action: {
                    isBillViewActive = true
                }){
                    Text("Manually Input Values")
                        .font(.custom("Avenir", size: 15))
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                        
                }
            }
        }
        .navigationDestination(isPresented: $isCameraActive){
            //Take Picture
        }
        .navigationDestination(isPresented: $isBillViewActive){
            BillView()
        }
    }
}

#Preview {
    SplitView()
}
