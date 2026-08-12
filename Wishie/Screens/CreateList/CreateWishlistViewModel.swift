//
//  CreateWishlistViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import Foundation
import UIKit

class CreateWishlistViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var dueDate: Date = Date()
    @Published var items: [WishlistItem] = []
    @Published var selectedTheme: GradientTheme?
    @Published var isFetchingMetadata: Bool = false
    @Published var metadataFetchError: String? = nil
    private var createWishListService: WishlistServiceProtocol
    private var productMetadataService: ProductMetadataServiceProtocol

    init(createWishListService: WishlistServiceProtocol = WishlistService(), productMetadataService: ProductMetadataServiceProtocol = ProductMetadataService()) {
        self.createWishListService = createWishListService
        self.productMetadataService = productMetadataService
    }
    func saveItem() async throws -> WishlistModel {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            throw NSError(
                domain: "UserError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
            )
        }
        let wishList = WishlistModel(
            name: name,
            description: description,
            dueDate: dueDate,
            items: items,
            themeColor: selectedTheme?.rawValue,
            userCreateId: userId)
        return try await createWishListService.createWishlist(wishList: wishList)
    }

    @MainActor
    func fetchProductMetadata(from urlString: String) async -> Result<ProductMetadata, Error> {
        isFetchingMetadata = true
        metadataFetchError = nil
        do {
            let metadata = try await productMetadataService.fetchMetadata(from: urlString)
            isFetchingMetadata = false
            return .success(metadata)
        } catch {
            isFetchingMetadata = false
            metadataFetchError = error.localizedDescription
            return .failure(error)
        }
    }

    func addItemFromMetadata(_ metadata: ProductMetadata) {
        let item = WishlistItem(
            name: metadata.title,
            description: metadata.productDescription,
            image: metadata.imageUrl,
            localImage: metadata.localImage,
            itemLink: metadata.productUrl,
            price: metadata.price
        )
        items.append(item)
    }
}

