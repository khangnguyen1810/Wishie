//
//  HomeViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 9/2/26.
//

import Foundation
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    @Published var myWishlists: [(WishlistModel, UserModel)] = []
    @Published var myFriendWishlists: [(WishlistModel, UserModel)] = []
    @Published var isGettingList: Bool = false
    @Published var errorMessage: String = ""
    private var service: WishlistServiceProtocol
    private var userWishlistsListener: ListenerRegistration?
    private var wishlistListeners: [ListenerRegistration] = []

    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    deinit {
        userWishlistsListener?.remove()
        wishlistListeners.forEach { $0.remove() }
    }

    func getListWishlist() async {
        do {
            isGettingList = true
            let result = try await service.getUserWishlists()
            switch result {
            case .success(let list):
                isGettingList = false
                guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
                   
                   self.myWishlists = list.filter {
                       $0.0.members[userId] == .owner && !$0.0.isArchived
                   }

                   self.myFriendWishlists = list.filter {
                       $0.0.members[userId] == .member && !$0.0.isArchived
                   }
            case .failure(let error):
                isGettingList = false
                self.errorMessage = error.localizedDescription
            }
        } catch {
            isGettingList = false
            self.errorMessage = error.localizedDescription
        }
    }

    private func setWishlistListeners(wishlistIds: [String]) {
        wishlistListeners.forEach { $0.remove() }
        wishlistListeners = wishlistIds.map { id in
            service.observeWishlist(by: id, onChange: { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refreshWishlists()
                }
            }, onError: { _ in })
        }
    }

    private func refreshWishlists() async {
        do {
            let result = try await service.getUserWishlists()
            switch result {
            case .success(let list):
                isGettingList = false
                guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
                self.myWishlists = list.filter { $0.0.members[userId] == .owner && !$0.0.isArchived }
                self.myFriendWishlists = list.filter { $0.0.members[userId] == .member && !$0.0.isArchived }
            case .failure(let error):
                isGettingList = false
                self.errorMessage = error.localizedDescription
            }
        } catch {
            isGettingList = false
            self.errorMessage = error.localizedDescription
        }
    }

    func startObservingWishlists() {
        isGettingList = myWishlists.isEmpty && myFriendWishlists.isEmpty
        userWishlistsListener?.remove()
        userWishlistsListener = service.observeUserWishlistIds { [weak self] ids in
            Task { @MainActor [weak self] in
                self?.setWishlistListeners(wishlistIds: ids)
                await self?.refreshWishlists()
            }
        }
    }

    func deleteWishlist(wishlistId: String) async {
        do {
            let result = try await service.deleteWishlist(wishlistId:  wishlistId)
            switch result {
            case .success(let success):
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    func leaveWishlist(wishlistId: String) async {
        do {
            let result = try await service.leaveWishlist(wishListId:  wishlistId)
            switch result {
            case .success(let success):
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    func archiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: true)
            switch result {
            case .success(let success):
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
