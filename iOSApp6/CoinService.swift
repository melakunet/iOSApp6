// CoinService.swift
// CoinWatch — fetches live crypto data from the CoinGecko public API

import Foundation

// Time ranges available for the price chart
enum ChartRange: String, CaseIterable {
    case day   = "1"
    case week  = "7"
    case month = "30"

    // Short label shown in the segmented picker
    var label: String {
        switch self {
        case .day:   return "1D"
        case .week:  return "1W"
        case .month: return "1M"
        }
    }
}

// Friendly errors returned when the server responds but data cannot be used
enum CoinServiceError: LocalizedError {
    case rateLimited  // HTTP 429: the free API rate limit was hit
    case badResponse  // any other non-2xx status

    var errorDescription: String? {
        switch self {
        case .rateLimited: return "Too many requests — please wait a moment and try again"
        case .badResponse: return "Could not load data from the server"
        }
    }
}

// Shared network service for all CoinGecko API calls
final class CoinService {

    // Single shared instance used throughout the app
    static let shared = CoinService()

    private init() {}

    // Plain decoder — Coin uses explicit CodingKeys so no strategy is needed
    private let decoder = JSONDecoder()

    // How long a cached result stays fresh before the network is hit again
    private let cacheTTL: TimeInterval = 60

    // Cached top-coins list and the time it was last fetched
    private var cachedCoins: [Coin] = []
    private var coinsLastFetched: Date?

    // Cached chart data; keyed by "coinId-days" e.g. "bitcoin-7"
    private var chartCache: [String: ([PricePoint], Date)] = [:]

    // Fetches the top 100 coins by market cap from CoinGecko
    // Pass forceRefresh: true (e.g. on pull-to-refresh) to skip the 60-second cache
    func fetchTopCoins(forceRefresh: Bool = false) async throws -> [Coin] {
        // Return the in-memory cache if it is still fresh
        if !forceRefresh,
           let lastFetched = coinsLastFetched,
           Date().timeIntervalSince(lastFetched) < cacheTTL,
           !cachedCoins.isEmpty {
            return cachedCoins
        }
        let urlString = "https://api.coingecko.com/api/v3/coins/markets" +
                        "?vs_currency=usd&order=market_cap_desc" +
                        "&per_page=100&page=1&price_change_percentage=24h"
        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        // Decode each element individually so one coin with missing fields
        // does not cause the entire list to fail
        let wrapped = try decoder.decode([FailableCoin].self, from: data)
        let coins = wrapped.compactMap { $0.value }
        // If every element silently failed, log the raw body so the cause is visible
        if coins.isEmpty {
            print("[CoinService] All coins failed to decode. Raw response:")
            print(String(data: data, encoding: .utf8) ?? "<non-UTF8 body>")
        }
        // Store the fresh result so calls within the TTL window skip the network
        cachedCoins = coins
        coinsLastFetched = Date()
        return coins
    }

    // Fetches price history for a given coin over the requested time range
    // Pass forceRefresh: true (e.g. when the user taps Retry) to bypass the cache
    func fetchChart(coinId: String, range: ChartRange = .week, forceRefresh: Bool = false) async throws -> [PricePoint] {
        let cacheKey = "\(coinId)-\(range.rawValue)"
        // Return the cached chart if it is still fresh
        if !forceRefresh,
           let (cached, date) = chartCache[cacheKey],
           Date().timeIntervalSince(date) < cacheTTL {
            return cached
        }
        let urlString = "https://api.coingecko.com/api/v3/coins/\(coinId)" +
                        "/market_chart?vs_currency=usd&days=\(range.rawValue)"
        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        // "prices" is an array of [timestamp_ms, price] pairs
        let raw = try decoder.decode(ChartResponse.self, from: data)
        let points = raw.prices.map { pair in
            PricePoint(date: Date(timeIntervalSince1970: pair[0] / 1000), price: pair[1])
        }
        // Store for future calls within the TTL window
        chartCache[cacheKey] = (points, Date())
        return points
    }

    // Throws a typed error based on the HTTP status code; 429 gets a friendly rate-limit message
    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw CoinServiceError.badResponse
        }
        if http.statusCode == 429 {
            throw CoinServiceError.rateLimited
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CoinServiceError.badResponse
        }
    }
}

// Used only to decode the top-level chart JSON structure
private struct ChartResponse: Decodable {
    let prices: [[Double]]  // each element is [timestamp_ms, price]
}

// Wraps a single Coin decode attempt so a bad element skips instead of crashing the list
private struct FailableCoin: Decodable {
    let value: Coin?
    init(from decoder: Decoder) throws {
        value = try? Coin(from: decoder)
    }
}
