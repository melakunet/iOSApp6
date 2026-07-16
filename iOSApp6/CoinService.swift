// CoinService.swift
// CoinWatch — fetches live crypto data from the CoinGecko public API

import Foundation

// Shared network service for all CoinGecko API calls
final class CoinService {

    // Single shared instance used throughout the app
    static let shared = CoinService()

    private init() {}

    // Decoder configured to convert snake_case JSON keys to camelCase Swift properties
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // Fetches the top 100 coins by market cap from CoinGecko
    func fetchTopCoins() async throws -> [Coin] {
        let urlString = "https://api.coingecko.com/api/v3/coins/markets" +
                        "?vs_currency=usd&order=market_cap_desc" +
                        "&per_page=100&page=1&price_change_percentage=24h"
        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try decoder.decode([Coin].self, from: data)
    }

    // Fetches 7-day price history for a given coin and converts it to PricePoint values
    func fetchChart(coinId: String) async throws -> [PricePoint] {
        let urlString = "https://api.coingecko.com/api/v3/coins/\(coinId)" +
                        "/market_chart?vs_currency=usd&days=7"
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
