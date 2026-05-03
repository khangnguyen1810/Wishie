//
//  WishlistDetailViewController.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/3/26.
//

import Foundation
import UIKit

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
    @Published var joinSucceed: Bool = false
    @Published var joinFailed: Bool = false
    @Published var joinErrorMessage: String = ""
    private var wishlistService: WishlistServiceProtocol
    init(wishlistService: WishlistServiceProtocol = WishlistService()) {
        self.wishlistService = wishlistService
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
                await getWishlistInfo(wishListId: wishlistId)
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
            isShowLoading = false
        } catch {
            isShowLoading = false
            print(error)
        }
    }
    
    func setInitialWishlist(_ wishlist: WishlistModel) {
        self.wishlistInfo = wishlist
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
                await getWishlistInfo(wishListId: wishListId)
            case .failure(let failure):
                isShowLoading = false
                print(failure.localizedDescription)
            }
        } catch {
            isShowLoading = false
            print(error)
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
            print(error)
        }
    }
}
