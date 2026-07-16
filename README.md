# CoinWatch (iOSApp6)

CoinWatch is an iOS app that shows live cryptocurrency prices for the top 100 coins by market cap. Each coin has a detail screen with a 7-day price chart that supports 1D, 1W, and 1M time ranges and touch scrubbing so you can drag across the chart to see the price at any point in time. Users can star coins to save them to a personal watchlist that syncs across sessions via Firebase.

## Features

- Async/await networking with `URLSession`
- `Codable` JSON decoding with explicit `CodingKeys`
- `NavigationStack` with programmatic `NavigationLink`
- Swift Charts with interactive touch scrubbing and 1D / 1W / 1M range picker
- `.searchable` coin filter in the Markets tab
- `.refreshable` pull-to-refresh on both tabs
- `TabView` with badge showing watchlist count
- Swipe-to-remove on watchlist rows
- `AsyncImage` for remote coin icons
- Firebase Anonymous Authentication (automatic, no sign-in screen needed)
- Cloud Firestore real-time watchlist synced across launches
- Animated landing screen with spinning coin and pulse effects

## Data source

Live price data from the free CoinGecko public API (https://api.coingecko.com), no API key required.

## Backend

Firebase — Anonymous Authentication + Cloud Firestore.

## How to run

1. Open `iOSApp6.xcodeproj` in Xcode.
2. Select an iOS simulator (iOS 17 or later).
3. Press **Run** (⌘R).
