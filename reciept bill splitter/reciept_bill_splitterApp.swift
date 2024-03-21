//
//  reciept_bill_splitterApp.swift
//  reciept bill splitter
//
//  Created by Simon Huang on 2/18/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
      //let providerFactory = AppCheckDebugProviderFactory()
      //AppCheck.setAppCheckProviderFactory(providerFactory)

      
      FirebaseApp.configure()
      
      let db = Firestore.firestore()
      
      return true
  }
}
@main



struct reciept_bill_splitterApp: App {
    
    // Register app delegate for firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
        }
    }
    
}
