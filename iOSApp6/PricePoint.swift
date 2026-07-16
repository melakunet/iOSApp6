// PricePoint.swift
// CoinWatch — a single price sample used to draw charts

import Foundation

// One data point on a price chart: a moment in time and the price at that moment
struct PricePoint: Identifiable {
    var id: UUID = UUID()  // unique identifier required by Identifiable
    let date: Date         // the timestamp for this price
    let price: Double      // the price in USD at that time
}
