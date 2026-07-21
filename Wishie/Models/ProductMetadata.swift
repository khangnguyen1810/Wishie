import Foundation
import UIKit

struct ProductMetadata: Hashable {
    let title: String
    let productDescription: String
    let imageUrl: String?
    let productUrl: String
    let price: String?
    /// Set when the metadata came from LinkPresentation, which hands back a
    /// decoded image rather than a URL. Mirrors `WishlistItem.localImage`.
    let localImage: UIImage?

    init(
        title: String,
        productDescription: String,
        imageUrl: String?,
        productUrl: String,
        price: String?,
        localImage: UIImage? = nil
    ) {
        self.title = title
        self.productDescription = productDescription
        self.imageUrl = imageUrl
        self.productUrl = productUrl
        self.price = price
        self.localImage = localImage
    }
}

extension ProductMetadata {
    /// True when this metadata carries an image in either representation.
    var hasImage: Bool {
        localImage != nil || imageUrl?.isEmpty == false
    }
}
