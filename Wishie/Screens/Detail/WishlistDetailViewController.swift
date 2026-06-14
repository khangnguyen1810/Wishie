//
//  WishlistDetailViewController.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/3/26.
//

import Foundation
import UIKit
import FirebaseFirestore

@MainActor
class WishlistDetailViewController: ObservableObject {
    @Published var itemSelected: WishlistItem = WishlistItem()
    @Published var isChoosed: Bool = false
    @Published var errorMessage: String = ""
    @Published var isShowError: Bool = false
    @Published var isShowLoading: Bool = false
    @Published var editedName: String = ""
    @Published var editedDescription: String = ""
    @Published var selectedImage: UIImage? = nil
    @Published var wishlistInfo: WishlistModel = WishlistModel(
        name: "",
        userCreateId: ""
    )
    @Published var showBottomSheet = false
    @Published var showReserveConfirmation: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var joinSucceed: Bool = false
    @Published var joinFailed: Bool = false
    @Published var joinErrorMessage: String = ""
    @Published var memberUsers: [UserModel] = []
    private var wishlistService: WishlistServiceProtocol
    private var authService: AuthenticateServiceProtocol
    private var wishlistListener: ListenerRegistration?
    init(wishlistService: WishlistServiceProtocol = WishlistService(), authService: AuthenticateServiceProtocol = AuthenticateService()) {
        self.wishlistService = wishlistService
        self.authService = authService
    }

    deinit {
        wishlistListener?.remove()
    }

    func startObservingWishlist(wishlistId: String, showInitialLoading: Bool = false) {
        isShowLoading = showInitialLoading
        wishlistListener?.remove()
        wishlistListener = wishlistService.observeWishlist(by: wishlistId, onChange: { [weak self] updatedWishlist in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.wishlistInfo = updatedWishlist
                self.isShowLoading = false
                await self.fetchMemberUsers()
            }
        }, onError: { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isShowLoading = false
            }
        })
    }
    
    func pickItem(wishlistId: String) async {
        do {
            isShowLoading = true
            let result =
            try await wishlistService
                .pickItem(wishlistId: wishlistId, itemId: itemSelected.id)
            switch result {
            case .success(_):
                isShowLoading = false
                isChoosed = true
            case .failure(let failure):
                isShowLoading = false
                errorMessage = failure.localizedDescription
                isShowError = true
            }
        } catch {
            isShowLoading = false
            errorMessage = error.localizedDescription
            isShowError = true
        }
    }
    func getWishlistInfo(wishListId: String) async {
        do {
            isShowLoading = true
            wishlistInfo = try await wishlistService
                .getWishlist(by: wishListId).0
            await fetchMemberUsers()
            isShowLoading = false
        } catch {
            isShowLoading = false
            errorMessage = error.localizedDescription
            isShowError = true
        }
    }
    
    func fetchMemberUsers() async {
        let memberIds = Array(wishlistInfo.members.keys)
        var users: [UserModel] = []
        for userId in memberIds {
            if let user = try? await authService.getUserInfo(by: userId) {
                users.append(user)
            }
        }
        memberUsers = users
    }
    
    func setInitialWishlist(_ wishlist: WishlistModel) {
        self.wishlistInfo = wishlist
        Task {
            await fetchMemberUsers()
        }
    }
    
    func editWishlistItem(wishListId: String) async {
        do {
            isShowLoading = true
            let result =
            try await wishlistService
                .updateWishlistItem(
                    wishlistId: wishListId,
                    itemId: itemSelected.id,
                    newName: editedName,
                    newDescription: editedDescription,
                    newImage: selectedImage
                )
            switch result {
            case .success(_):
                isShowLoading = false
            case .failure(let failure):
                isShowLoading = false
                errorMessage = failure.localizedDescription
                isShowError = true
            }
        } catch {
            isShowLoading = false
            errorMessage = error.localizedDescription
            isShowError = true
        }
    }
    func openProductLink() {
        guard let url = URL(string: itemSelected.itemLink) else {
            showBottomSheet = false
            isShowError = true
            errorMessage = "Product link is not valid, you can tell with owner"
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            if let webURL = URL(string: itemSelected.itemLink) {
                UIApplication.shared.open(webURL)
            }
        }
    }
    func joinWishlist(wishListId: String) async {
        do {
            isShowLoading = true
            let result = try await wishlistService.joinWishlist(wishListId: wishListId)
            switch result {
            case .success(_):
                isShowLoading = false
                joinSucceed = true
            case .failure(_):
                isShowLoading = false
                joinFailed = true
                joinErrorMessage = "You currently can't join this wishlist. Please try again."
            }
        } catch {
            isShowLoading = false
            joinFailed = true
            joinErrorMessage = "There are something wrong. Please try again."
        }
    }

    func deleteWishlistItem(wishlistId: String) async {
        do {
            isShowLoading = true
            let result = try await wishlistService.deleteWishlistItem(wishlistId: wishlistId, itemId: itemSelected.id)
            switch result {
            case .success(_):
                isShowLoading = false
            case .failure(let error):
                isShowLoading = false
                errorMessage = error.localizedDescription
                isShowError = true
            }
        } catch {
            isShowLoading = false
            errorMessage = error.localizedDescription
            isShowError = true
        }
    }

    func setMostDesired(wishlistId: String) async {
        do {
            isShowLoading = true
            let result = try await wishlistService.setMostDesired(wishlistId: wishlistId, itemId: itemSelected.id, isMostDesired: true)
            switch result {
            case .success(_):
                isShowLoading = false
            case .failure(let error):
                isShowLoading = false
                errorMessage = error.localizedDescription
                isShowError = true
            }
        } catch {
            isShowLoading = false
            errorMessage = error.localizedDescription
            isShowError = true
        }
    }
}
