// CoinDetailView.swift
// CoinWatch — detail screen with interactive scrubbing chart and range picker

import SwiftUI
import Charts

// Shows detailed price info, a scrubable price chart, and key stats for one coin
struct CoinDetailView: View {
    let coin: Coin  // the coin whose chart and stats this screen shows

    // Shared watchlist passed down from the app root via the environment
    @EnvironmentObject var watchlist: WatchlistService

    // Chart price data for the selected time range
    @State private var chartPoints: [PricePoint] = []
    // True while chart data is loading
    @State private var isLoading = false
    // Holds an error message if the chart fetch fails
    @State private var errorMessage: String?
    // Scale used to give the star button a spring bounce on tap
    @State private var starScale: CGFloat = 1.0
    // Currently selected time range for the chart
    @State private var selectedRange: ChartRange = .week
    // The chart point the user is currently dragging over, or nil when not scrubbing
    @State private var selectedPoint: PricePoint?

    // Shows the scrubbed price while dragging, otherwise the coin's live price
    private var displayPrice: Double {
        selectedPoint?.price ?? coin.currentPrice
    }

    // Line color: green if the visible range went up overall, red if it went down
    private var chartColor: Color {
        guard let first = chartPoints.first, let last = chartPoints.last else { return .blue }
        return last.price >= first.price ? .green : .red
    }

    // Y-axis bounds with padding so the line fills the chart instead of starting from zero
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
            // Load chart data when the view first appears
            await loadChart()
        }
        .onChange(of: selectedRange) {
            // Reload whenever the user picks a different range
            Task { await loadChart() }
        }
    }

    // Star button that toggles the watchlist state with a spring bounce animation
    private var starButton: some View {
        let watched = watchlist.isWatched(coin.id)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { starScale = 1.5 }
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { starScale = 1.0 }
            }
            if watched { watchlist.remove(coinId: coin.id) } else { watchlist.add(coin: coin) }
        } label: {
            Image(systemName: watched ? "star.fill" : "star")
                .foregroundStyle(watched ? .yellow : .primary)
                .scaleEffect(starScale)
        }
    }

    // Header: icon, name, symbol, live/scrubbed price, and 24h change
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

            // Switches to the scrubbed price while the user drags on the chart
            Text(displayPrice, format: .currency(code: "USD"))
                .font(.system(size: 34, weight: .bold))
                .contentTransition(.numericText())

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

    // Range picker and chart content (spinner, error, or interactive chart)
    @ViewBuilder
    private var chartSection: some View {
        VStack(spacing: 12) {
            // Segmented picker to switch between 1D, 1W, and 1M
            Picker("Range", selection: $selectedRange) {
                ForEach(ChartRange.allCases, id: \.self) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else if let message = errorMessage {
                // Error state: friendly message and a retry button to try again immediately
                VStack(spacing: 12) {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await loadChart(forceRefresh: true) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
            } else if !chartPoints.isEmpty {
                Chart {
                    // Line and gradient fill for the price series
                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .foregroundStyle(chartColor)

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

                    // Vertical rule, dot, and annotation card shown while scrubbing
                    if let point = selectedPoint {
                        RuleMark(x: .value("Selected", point.date))
                            .foregroundStyle(Color.gray.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(
                                position: .top,
                                alignment: .center,
                                spacing: 4,
                                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                            ) {
                                scrubAnnotationCard(point: point)
                            }

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .foregroundStyle(chartColor)
                        .symbolSize(60)
                    }
                }
                .chartYScale(domain: priceRange)
                .frame(height: 220)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let anchor = proxy.plotFrame else { return }
                                        let plotFrame = geo[anchor]
                                        let x = value.location.x - plotFrame.origin.x
                                        guard x >= 0, x <= plotFrame.width else { return }
                                        if let date: Date = proxy.value(atX: x) {
                                            selectedPoint = nearestPoint(to: date)
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            selectedPoint = nil
                                        }
                                    }
                            )
                    }
                }
            }
        }
    }

    // Small card shown above the selected point with price and formatted date
    private func scrubAnnotationCard(point: PricePoint) -> some View {
        VStack(spacing: 2) {
            Text(point.price, format: .currency(code: "USD"))
                .font(.caption.bold())
            // 1D shows time; 1W and 1M show date only
            Text(selectedRange == .day
                 ? point.date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
                 : point.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // Returns the chart point whose date is closest to the given date
    private func nearestPoint(to date: Date) -> PricePoint? {
        chartPoints.min {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
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

    // Fetches chart data for the selected range and clears any active scrub point
    // Pass forceRefresh: true (e.g. Retry button) to bypass the 60-second cache
    private func loadChart(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        selectedPoint = nil
        do {
            chartPoints = try await CoinService.shared.fetchChart(
                coinId: coin.id, range: selectedRange, forceRefresh: forceRefresh
            )
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
