// WatchlistItem.swift
// CoinWatch — data model for a coin saved to the Firestore watchlist

import Foundation
import FirebaseFirestore

// One entry in the user's watchlist, stored as a Firestore document
struct WatchlistItem: Identifiable, Codable {
    @DocumentID var id: String?  // Firestore document ID, populated automatically on read
    var coinId: String           // CoinGecko coin identifier e.g. "bitcoin"
    var name: String             // display name e.g. "Bitcoin"
    var symbol: String           // ticker symbol e.g. "btc"
    var imageURL: String         // URL string for the coin icon
    var addedAt: Date            // timestamp when the user added this coin
}
