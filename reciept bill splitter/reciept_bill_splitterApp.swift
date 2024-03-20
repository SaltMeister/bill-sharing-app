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
import Stripe
class AppRouter: ObservableObject {
    static let shared = AppRouter()
    @Published var currentPage: String?
    
}

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Your existing setup code
        FirebaseApp.configure()
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        StripeAPI.defaultPublishableKey = "pk_test_51Ok9axKKu7GjlI2QUFnpxXO1l3w7udwBAThjlXxvJ5wn7JJLw3H1kWAYq73mJgz0NaFdk5qBLvqYDv0JFoRPNkXy00DKklUgdW"

        // More setup code as needed
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "yourapp", let host = url.host {
            switch host {
            case "onboarding":
                AppRouter.shared.currentPage = host // Update the app's routing state
                print("Handle onboarding flow")
            case "reauth":
                // Navigate to profile screen
                print("Navigate to profile screen")
            default:
                print("Unhandled URL host: \(host)")
            }
            return true
        }
        return false
    }
}

@main



struct reciept_bill_splitterApp: App {
    @ObservedObject var router = AppRouter.shared

    // Register app delegate for firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .environmentObject(router)
            }
        }
    
    }

