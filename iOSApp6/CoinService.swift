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

// Shared network service for all CoinGecko API calls
final class CoinService {

    // Single shared instance used throughout the app
    static let shared = CoinService()

    private init() {}

    // Plain decoder — Coin uses explicit CodingKeys so no strategy is needed
    private let decoder = JSONDecoder()

    // Fetches the top 100 coins by market cap from CoinGecko
    func fetchTopCoins() async throws -> [Coin] {
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
        return coins
    }

    // Fetches price history for a given coin over the requested time range
    func fetchChart(coinId: String, range: ChartRange = .week) async throws -> [PricePoint] {
        let urlString = "https://api.coingecko.com/api/v3/coins/\(coinId)" +
                        "/market_chart?vs_currency=usd&days=\(range.rawValue)"
        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)

        // "prices" is an array of [timestamp_ms, price] pairs
        let raw = try decoder.decode(ChartResponse.self, from: data)
        return raw.prices.map { pair in
            let date = Date(timeIntervalSince1970: pair[0] / 1000)
            return PricePoint(date: date, price: pair[1])
        }
    }

    // Throws an error if the HTTP status code is outside 200-299
    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
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
