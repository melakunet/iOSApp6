// iOSApp6App.swift
// CoinWatch — app entry point, Firebase setup, and environment injection

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct iOSApp6App: App {
    // Single WatchlistService instance shared across all views via the environment
    @StateObject private var watchlist = WatchlistService()

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
                .environmentObject(watchlist)
        }
    }
}
