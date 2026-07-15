//
//  iOSApp6App.swift
//  iOSApp6
//
//  Created by Etefworkie Melaku on 2026-07-15.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct iOSApp6App: App {

    // Configure Firebase when the app launches
    init() {
        FirebaseApp.configure()

        // Sign in anonymously so each device gets its own user ID
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
