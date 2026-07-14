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
    @Published var showReplaceMostDesiredConfirmation: Bool = false
    @Published var joinSucceed: Bool = false
    @Published var joinFailed: Bool = false
    @Published var joinErrorMessage: String = ""
    @Published var memberUsers: [UserModel] = []
    @Published var showAddItemOptionSheet: Bool = false
    @Published var showAddItemManualSheet: Bool = false
    @Published var showAddItemPasteLinkSheet: Bool = false
    @Published var showEditItemSheet: Bool = false
    @Published var newItemName: String = ""
    @Published var newItemDescription: String = ""
    @Published var newItemImage: UIImage? = nil
    @Published var newItemLink: String = ""
    @Published var isFetchingMetadata: Bool = false
    @Published var metadataFetchError: String? = nil
    @Published var newItemRemoteImageUrl: String? = nil
    @Published var newItemPrice: String = ""
    @Published var showDuplicateItemDialog: Bool = false
    private var wishlistService: WishlistServiceProtocol
    private var authService: AuthenticateServiceProtocol
    private var productMetadataService: ProductMetadataServiceProtocol
    private var wishlistListener: ListenerRegistration?
    init(wishlistService: WishlistServiceProtocol = WishlistService(), authService: AuthenticateServiceProtocol = AuthenticateService(), productMetadataService: ProductMetadataServiceProtocol = ProductMetadataService()) {
        self.wishlistService = wishlistService
        self.authService = authService
        self.productMetadataService = productMetadataService
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
                    newName: newItemName,
                    newDescription: newItemDescription,
                    newImage: newItemImage,
                    newPrice: newItemPrice
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

    /// The item currently holding the most-desired flag, if any.
    var currentMostDesiredItem: WishlistItem? {
        wishlistInfo.items.first(where: { $0.isMostDesired })
    }

    /// True when marking `itemSelected` would displace a different item that already holds the flag.
    var wouldReplaceMostDesired: Bool {
        guard !itemSelected.isMostDesired, let current = currentMostDesiredItem else { return false }
        return current.id != itemSelected.id
    }

    func setDesired(wishlistId: String, isDesired: Bool) async {
        do {
            isShowLoading = true
            let result = try await wishlistService.setMostDesired(wishlistId: wishlistId, itemId: itemSelected.id, isMostDesired: isDesired)
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

    func addNewWishlistItem(wishlistId: String) async {
        if !newItemLink.isEmpty && checkIfItemExists(withLink: newItemLink) {
            showDuplicateItemDialog = true
            isShowLoading = false
            return
        }
        
        isShowLoading = true
        do {
            var imageUrl: String? = nil
            if let localImage = newItemImage {
                imageUrl = try await wishlistService.upload(image: localImage, fileName: UUID().uuidString)
            } else if let remoteUrl = newItemRemoteImageUrl {
                imageUrl = remoteUrl
            }
            let item = WishlistItem(
                name: newItemName,
                description: newItemDescription,
                image: imageUrl,
                itemLink: newItemLink,
                price: newItemPrice
            )
            let result = try await wishlistService.addWishlistItem(wishlistId: wishlistId, item: item)
            switch result {
            case .success(_):
                newItemName = ""
                newItemDescription = ""
                newItemImage = nil
                newItemLink = ""
                newItemRemoteImageUrl = nil
                newItemPrice = ""
                metadataFetchError = nil
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

    func fetchProductMetadataForNewItem(from urlString: String) async {
        isFetchingMetadata = true
        metadataFetchError = nil
        do {
            let metadata = try await productMetadataService.fetchMetadata(from: urlString)
            setNewItemFromMetadata(metadata)
        } catch {
            metadataFetchError = error.localizedDescription
            newItemName = ""
            newItemDescription = ""
            newItemRemoteImageUrl = nil
            newItemPrice = ""
        }
        isFetchingMetadata = false
    }
    
    func checkIfItemExists(withLink link: String) -> Bool {
        let normalizedLink = link.trimmingCharacters(in: .whitespaces).lowercased()
        return wishlistInfo.items.contains { item in
            let itemLink = item.itemLink.trimmingCharacters(in: .whitespaces).lowercased()
            return !itemLink.isEmpty && itemLink == normalizedLink
        }
    }

    func setNewItemFromMetadata(_ metadata: ProductMetadata) {
        newItemName = metadata.title
        newItemDescription = metadata.productDescription
        newItemLink = metadata.productUrl
        newItemRemoteImageUrl = metadata.imageUrl
        newItemPrice = metadata.price ?? ""
    }
}
