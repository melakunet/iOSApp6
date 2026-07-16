// Coin.swift
// CoinWatch — data model for a single cryptocurrency from CoinGecko

import Foundation

// Represents one coin returned by the CoinGecko /coins/markets endpoint
struct Coin: Identifiable, Codable, Hashable {
    let id: String                         // unique coin identifier e.g. "bitcoin"
    let symbol: String                     // ticker symbol e.g. "btc"
    let name: String                       // display name e.g. "Bitcoin"
    let image: String                      // URL string for the coin icon
    let currentPrice: Double               // current price in USD
    let marketCap: Double?                 // total market cap in USD
    let priceChangePercentage24h: Double?  // 24-hour price change as a percentage
    let high24h: Double?                   // 24-hour high price in USD
    let low24h: Double?                    // 24-hour low price in USD

    // Explicit keys map exact JSON field names so decoding never depends on
    // convertFromSnakeCase, which would wrongly capitalise the "h" in "24h"
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice             = "current_price"
        case marketCap                = "market_cap"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case high24h                  = "high_24h"
        case low24h                   = "low_24h"
    }
}
