// MainTabView.swift
// CoinWatch — root tab bar with Markets and Watchlist tabs

import SwiftUI

// Root navigation container: two tabs for browsing all coins and viewing saved ones
struct MainTabView: View {
    // Watchlist count is read here to drive the badge on the Watchlist tab
    @EnvironmentObject var watchlist: WatchlistService

    var body: some View {
        TabView {
            // Markets tab: live prices for the top 100 coins
            CoinListView()
                .tabItem {
                    Label("Markets", systemImage: "chart.line.uptrend.xyaxis")
                }

            // Watchlist tab: shows a badge with the number of starred coins
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
                .badge(watchlist.items.count > 0 ? watchlist.items.count : 0)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(WatchlistService())
}
