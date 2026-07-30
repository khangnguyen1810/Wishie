import Testing
import Foundation
import UIKit
@testable import Wishie

@MainActor
struct WishlistDetailViewControllerAddSuggestedItemTests {

    private var anImage: UIImage { UIImage(systemName: "gift")! }

    @Test func addSuggestedItemUploadsLocalImageAndClearsIt() async throws {
        let wishlistService = MockWishlistService()
        wishlistService.uploadResult = .success("https://uploaded.example.com/from-gift-suggestion.jpg")
        let controller = WishlistDetailViewController(
            wishlistService: wishlistService,
            authService: MockAuthenticateService(),
            productMetadataService: MockProductMetadataService()
        )
        let item = WishlistItem(
            name: "Mechanical Keyboard",
            description: "Clicky keys",
            image: nil,
            localImage: anImage,
            itemLink: "https://ex.com/kb",
            price: "$80"
        )

        try await controller.addSuggestedItem(item, wishlistId: "wishlist-1")

        #expect(wishlistService.uploadCallCount == 1)
        #expect(wishlistService.lastUploadedImage === anImage)
        #expect(wishlistService.addedItems.count == 1)
        #expect(wishlistService.addedItems.first?.image == "https://uploaded.example.com/from-gift-suggestion.jpg")
        #expect(wishlistService.addedItems.first?.localImage == nil)
    }
}
