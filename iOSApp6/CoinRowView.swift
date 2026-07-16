// CoinRowView.swift
// CoinWatch — list row displaying one coin's key data

import SwiftUI

// Displays one coin in the Markets list: icon, name, price, and 24h change
struct CoinRowView: View {
    let coin: Coin

    var body: some View {
        HStack(spacing: 12) {
            // Coin icon loaded from URL, clipped to a circle
            AsyncImage(url: URL(string: coin.image)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            // Coin name and ticker symbol stacked vertically
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .font(.headline)
                Text(coin.symbol.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Current price and 24h change aligned to the trailing edge
            VStack(alignment: .trailing, spacing: 2) {
                Text(coin.currentPrice, format: .currency(code: "USD"))
                    .font(.headline)
                priceChangeLabel
            }
        }
        .padding(.vertical, 4)
    }

    // Builds the 24h change label: green arrow up, red arrow down, or gray dash if nil
    @ViewBuilder
    private var priceChangeLabel: some View {
        if let change = coin.priceChangePercentage24h {
            let positive = change >= 0
            Label(
                String(format: "%.2f%%", abs(change)),
                systemImage: positive ? "arrow.up" : "arrow.down"
            )
            .font(.caption)
            .foregroundStyle(positive ? Color.green : Color.red)
        } else {
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
