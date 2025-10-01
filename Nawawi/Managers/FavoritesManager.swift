//
//  FavoritesManager.swift
//  Nawawi
//
//  Manages user's favorite hadiths with persistence
//  Extracted from AppState following Single Responsibility Principle
//

import Foundation
import SwiftUI
import Combine

@MainActor
class FavoritesManager: ObservableObject {
    @Published var favorites: Set<Int> = []

    @AppStorage("favorites") private var favoritesData = Data()

    init() {
        loadFavorites()
    }

    // MARK: - Public Methods

    func toggleFavorite(_ hadithNumber: Int) {
        if favorites.contains(hadithNumber) {
            favorites.remove(hadithNumber)
        } else {
            favorites.insert(hadithNumber)
        }
        saveFavorites()
    }

    func isFavorite(_ hadithNumber: Int) -> Bool {
        favorites.contains(hadithNumber)
    }

    func clearAllFavorites() {
        favorites.removeAll()
        saveFavorites()
    }

    // MARK: - Persistence

    private func loadFavorites() {
        if let decoded = try? JSONDecoder().decode(Set<Int>.self, from: favoritesData) {
            favorites = decoded
        }
    }

    func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            favoritesData = encoded
        }
    }
}
