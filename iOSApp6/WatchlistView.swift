// WatchlistView.swift
// CoinWatch — saved coins screen with live prices and swipe-to-remove

import SwiftUI

// Shows the coins the user has starred, with live prices loaded from CoinGecko
struct WatchlistView: View {
    // Shared watchlist state from the environment
    @EnvironmentObject var watchlist: WatchlistService

    // Full coin data used to show live prices next to each watchlist item
    @State private var coins: [Coin] = []
    // True while the coin list is being fetched
    @State private var isLoading = false

    // Finds the live Coin for a watchlist item so prices can be displayed
    private func liveCoin(for item: WatchlistItem) -> Coin? {
        coins.first { $0.id == item.coinId }
    }

    var body: some View {
        NavigationStack {
            Group {
                if watchlist.items.isEmpty {
                    // Empty state shown when no coins have been starred yet
                    ContentUnavailableView(
                        "No coins yet",
                        systemImage: "star",
                        description: Text("Tap the star on any coin to follow it")
                    )
                } else {
                    List {
                        ForEach(watchlist.items) { item in
                            watchlistRow(for: item)
                                .swipeActions(edge: .trailing) {
                                    // Red swipe button removes the coin from the watchlist
                                    Button(role: .destructive) {
                                        watchlist.remove(coinId: item.coinId)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .refreshable {
                        await loadCoins()
                    }
                }
            }
            .navigationTitle("Watchlist")
            .navigationDestination(for: Coin.self) { coin in
                CoinDetailView(coin: coin)
            }
            .task {
                // Load top 100 coins so live prices are ready for each row
                await loadCoins()
            }
        }
    }

    // Wraps the row in a NavigationLink when the live coin is available; plain row otherwise
    @ViewBuilder
    private func watchlistRow(for item: WatchlistItem) -> some View {
        if let coin = liveCoin(for: item) {
            NavigationLink(value: coin) {
                rowContent(item: item, coin: coin)
            }
        } else {
            rowContent(item: item, coin: nil)
        }
    }

    // Visual content of one row: icon, name, symbol, and optional live price and 24h change
    private func rowContent(item: WatchlistItem, coin: Coin?) -> some View {
        HStack(spacing: 12) {
            // Coin icon loaded from the stored URL
            AsyncImage(url: URL(string: item.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            // Name and symbol
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                Text(item.symbol.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Price and 24h change appear once the live coin data is loaded
            if let coin {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(coin.currentPrice, format: .currency(code: "USD"))
                        .font(.headline)
                    if let change = coin.priceChangePercentage24h {
                        let positive = change >= 0
                        Label(
                            String(format: "%.2f%%", abs(change)),
                            systemImage: positive ? "arrow.up" : "arrow.down"
                        )
                        .font(.caption)
                        .foregroundStyle(positive ? .green : .red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // Fetches the top 100 coins to populate live prices for each watchlist row
    private func loadCoins() async {
        isLoading = true
        do {
            coins = try await CoinService.shared.fetchTopCoins()
        } catch { }
        isLoading = false
    }
}

#Preview {
    WatchlistView()
        .environmentObject(WatchlistService())
}
