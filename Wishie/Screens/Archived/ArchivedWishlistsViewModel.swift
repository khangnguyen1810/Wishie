//
//  ArchivedWishlistsViewModel.swift
//  Wishie
//

import Foundation

@MainActor
class ArchivedWishlistsViewModel: ObservableObject {
    @Published var archivedWishlists: [(WishlistModel, UserModel)] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    func loadArchivedWishlists() async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let wishlists = try await service.getUserWishlists()
            let owned = wishlists.filter { $0.members[userId] == .owner && $0.isArchived }
            archivedWishlists = await service.pairWithOwnerProfiles(owned)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func unarchiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: false)
            switch result {
            case .success:
                await loadArchivedWishlists()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteWishlist(wishlistId: String) async {
        do {
            let result = try await service.deleteWishlist(wishlistId: wishlistId)
            switch result {
            case .success:
                await loadArchivedWishlists()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
