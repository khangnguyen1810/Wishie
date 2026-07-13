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
        do {
            isLoading = true
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                isLoading = false
                return
            }
            let result = try await service.getUserWishlists()
            switch result {
            case .success(let list):
                isLoading = false
                self.archivedWishlists = list.filter {
                    $0.0.members[userId] == .owner && $0.0.isArchived
                }
            case .failure(let error):
                isLoading = false
                self.errorMessage = error.localizedDescription
            }
        } catch {
            isLoading = false
            self.errorMessage = error.localizedDescription
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
