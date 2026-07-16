// CoinListView.swift
// CoinWatch — Markets screen showing the top 100 coins live

import SwiftUI

// Main Markets screen: a searchable, refreshable list of live coin prices
struct CoinListView: View {
    // Full list of coins fetched from CoinGecko
    @State private var coins: [Coin] = []
    // Text the user has typed into the search bar
    @State private var searchText = ""
    // True while the first network request is in progress
    @State private var isLoading = false
    // Holds an error description if fetching fails
    @State private var errorMessage: String?

    // Returns all coins when search is empty, otherwise filters by name or symbol
    private var filteredCoins: [Coin] {
        guard !searchText.isEmpty else { return coins }
        return coins.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading prices...")
                } else if let message = errorMessage {
                    // Error state with a retry button
                    ContentUnavailableView {
                        Label("Cannot Load Prices", systemImage: "wifi.slash")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry") {
                            Task { await loadCoins() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    // Coin list with search and pull-to-refresh
                    List(filteredCoins) { coin in
                        CoinRowView(coin: coin)
                    }
                    .searchable(
                        text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search coins"
                    )
                    .refreshable {
                        await loadCoins()
                    }
                }
            }
            .navigationTitle("Markets")
            .task {
                // Fetch coins once when the view first appears
                await loadCoins()
            }
        }
    }

    // Fetches the top 100 coins and updates state; shows a spinner only on the first load
    private func loadCoins() async {
        isLoading = coins.isEmpty
        errorMessage = nil
        do {
            coins = try await CoinService.shared.fetchTopCoins()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    CoinListView()
}
