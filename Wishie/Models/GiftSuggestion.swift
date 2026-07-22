import Foundation

struct GiftIdea: Hashable {
    let name: String
    let description: String
    let price: String
    let link: String

    static func parse(from data: Any?) -> [GiftIdea] {
        guard
            let dict = data as? [String: Any],
            let rawIdeas = dict["ideas"] as? [[String: Any]]
        else { return [] }

        return rawIdeas.compactMap { entry in
            guard
                let name = (entry["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                !name.isEmpty,
                let link = (entry["link"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                !link.isEmpty
            else { return nil }

            return GiftIdea(
                name: name,
                description: (entry["description"] as? String) ?? "",
                price: (entry["price"] as? String) ?? "",
                link: link
            )
        }
    }
}

struct GiftSuggestion: Hashable, Identifiable {
    let idea: GiftIdea
    let metadata: ProductMetadata

    var id: String { metadata.productUrl }

    func toWishlistItem() -> WishlistItem {
        WishlistItem(
            name: metadata.title.isEmpty ? idea.name : metadata.title,
            description: metadata.productDescription.isEmpty ? idea.description : metadata.productDescription,
            image: metadata.imageUrl,
            localImage: metadata.localImage,
            itemLink: metadata.productUrl,
            price: (metadata.price?.isEmpty == false ? metadata.price : idea.price)
        )
    }
}
