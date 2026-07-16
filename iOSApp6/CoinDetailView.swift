// CoinDetailView.swift
// CoinWatch — detail screen for a single coin with a 7-day price chart

import SwiftUI
import Charts

// Shows detailed price info, a 7-day chart, and key stats for one coin
struct CoinDetailView: View {
    let coin: Coin

    // Shared watchlist passed down from the app root via the environment
    @EnvironmentObject var watchlist: WatchlistService

    // 7-day chart data fetched from CoinGecko
    @State private var chartPoints: [PricePoint] = []
    // True while chart data is loading
    @State private var isLoading = false
    // Holds an error message if the chart fetch fails
    @State private var errorMessage: String?
    // Scale used to give the star button a spring bounce on tap
    @State private var starScale: CGFloat = 1.0

    // Line color: green if 7-day price went up, red if it went down
    private var chartColor: Color {
        guard let first = chartPoints.first, let last = chartPoints.last else { return .blue }
        return last.price >= first.price ? .green : .red
    }

    // Y-axis range with padding so the line fills the chart instead of starting from zero
    private var priceRange: ClosedRange<Double> {
        guard let min = chartPoints.map(\.price).min(),
              let max = chartPoints.map(\.price).max() else { return 0...1 }
        let pad = (max - min) * 0.1
        return (min - pad)...(max + pad)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                chartSection
                statsSection
            }
            .padding()
        }
        .navigationTitle(coin.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                starButton
            }
        }
        .task {
            // Load 7-day chart data when the view appears
            await loadChart()
        }
    }

    // Star button that toggles the watchlist state with a spring bounce animation
    private var starButton: some View {
        let watched = watchlist.isWatched(coin.id)
        return Button {
            // Bounce the icon then toggle
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                starScale = 1.5
            }
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    starScale = 1.0
                }
            }
            if watched {
                watchlist.remove(coinId: coin.id)
            } else {
                watchlist.add(coin: coin)
            }
        } label: {
            Image(systemName: watched ? "star.fill" : "star")
                .foregroundStyle(watched ? .yellow : .primary)
                .scaleEffect(starScale)
        }
    }

    // Header: icon, name, symbol, current price, and 24h change
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: coin.image)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                Text(coin.name)
                    .font(.title2.bold())

                Text(coin.symbol.uppercased())
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Large price display
            Text(coin.currentPrice, format: .currency(code: "USD"))
                .font(.system(size: 34, weight: .bold))

            // 24h change with direction arrow
            priceChangeLabel
        }
    }

    // 24h change label: green up arrow, red down arrow, or dash if nil
    @ViewBuilder
    private var priceChangeLabel: some View {
        if let change = coin.priceChangePercentage24h {
            let positive = change >= 0
            Label(
                String(format: "%.2f%% (24h)", abs(change)),
                systemImage: positive ? "arrow.up" : "arrow.down"
            )
            .font(.subheadline)
            .foregroundStyle(positive ? .green : .red)
        } else {
            Text("—")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // Chart section: spinner while loading, error message, or the line chart
    @ViewBuilder
    private var chartSection: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 220)
        } else if let message = errorMessage {
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 220)
        } else if !chartPoints.isEmpty {
            Chart {
                ForEach(chartPoints) { point in
                    // Line connecting all price points
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(chartColor)

                    // Gradient fill below the line
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.25), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartYScale(domain: priceRange)
            .frame(height: 220)
        }
    }

    // 2-column stat grid showing 24h high, 24h low, and market cap
    private var statsSection: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            statCard(
                label: "24h High",
                value: coin.high24h.map { $0.formatted(.currency(code: "USD")) } ?? "—"
            )
            statCard(
                label: "24h Low",
                value: coin.low24h.map { $0.formatted(.currency(code: "USD")) } ?? "—"
            )
            statCard(
                label: "Market Cap",
                value: coin.marketCap.map { formatCompact($0) } ?? "—"
            )
        }
    }

    // One stat card: caption label above a bold value on a gray rounded background
    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // Formats a large dollar amount compactly using T, B, or M suffix
    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000_000_000 {
            return String(format: "$%.2fT", value / 1_000_000_000_000)
        } else if value >= 1_000_000_000 {
            return String(format: "$%.2fB", value / 1_000_000_000)
        } else {
            return String(format: "$%.2fM", value / 1_000_000)
        }
    }

    // Fetches the 7-day price chart for this coin from CoinGecko
    private func loadChart() async {
        isLoading = true
        errorMessage = nil
        do {
            chartPoints = try await CoinService.shared.fetchChart(coinId: coin.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        CoinDetailView(coin: Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
            currentPrice: 65000,
            marketCap: 1_280_000_000_000,
            priceChangePercentage24h: 2.34,
            high24h: 66500,
            low24h: 63200
        ))
        .environmentObject(WatchlistService())
    }
}
