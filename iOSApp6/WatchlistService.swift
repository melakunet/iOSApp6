// WatchlistService.swift
// CoinWatch — manages the user's watchlist in Firestore with real-time updates

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// Observable watchlist that stays in sync with Firestore in real time
final class WatchlistService: ObservableObject {
    // Coins the user has starred, ordered newest first
    @Published private(set) var items: [WatchlistItem] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?        // active Firestore snapshot listener
    private var authHandle: AuthStateDidChangeListenerHandle?  // temporary auth listener

    init() {
        if let uid = Auth.auth().currentUser?.uid {
            // User is already signed in — attach the listener right away
            attachListener(uid: uid)
        } else {
            // Anonymous sign-in may still be in flight; wait for auth state to settle
            authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                guard let self, let uid = user?.uid else { return }
                self.attachListener(uid: uid)
                // Auth listener is no longer needed once the user exists
                if let handle = self.authHandle {
                    Auth.auth().removeStateDidChangeListener(handle)
                    self.authHandle = nil
                }
            }
        }
    }

    deinit {
        listener?.remove()
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // Subscribes to the user's watchlist collection and refreshes items on every change
    private func attachListener(uid: String) {
        let ref = db.collection("users").document(uid)
                    .collection("watchlist")
                    .order(by: "addedAt", descending: true)
        listener = ref.addSnapshotListener { [weak self] snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            self?.items = docs.compactMap { try? $0.data(as: WatchlistItem.self) }
        }
    }

    // Saves a coin to the watchlist using the coin's id as the document name to prevent duplicates
    func add(coin: Coin) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let item = WatchlistItem(
            coinId: coin.id,
            name: coin.name,
            symbol: coin.symbol,
            imageURL: coin.image,
            addedAt: Date()
        )
        let ref = db.collection("users").document(uid)
                    .collection("watchlist").document(coin.id)
        try? ref.setData(from: item)
    }

    // Deletes a coin's document from the watchlist
    func remove(coinId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid)
          .collection("watchlist").document(coinId).delete()
    }

    // Returns true if the given coin id is already in the watchlist
    func isWatched(_ coinId: String) -> Bool {
        items.contains { $0.coinId == coinId }
    }
}
