import Foundation

struct WishlistMemberResponse: Decodable {
    let wishlistId: String
    let userId: String
    let role: String   // "owner" | "member"
    let joinedAt: String
}

struct WishlistItemResponse: Decodable {
    let id: String
    let wishlistId: String
    let name: String
    let description: String
    let imageUrl: String?
    let isPicked: Bool
    let pickedBy: String?
    let itemLink: String
    let price: String?
    let isMostDesired: Bool
}

struct WishlistResponse: Decodable {
    let id: String
    let name: String
    let description: String
    let ownerId: String
    let dueDate: String
    let colorTheme: String?
    let isArchived: Bool
    let createdAt: String
    let members: [WishlistMemberResponse]?
    let items: [WishlistItemResponse]?
}

struct ProfileResponse: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let dateOfBirth: String?
    let avatarUrl: String?
    let interests: [String]
    let hasCompletedInterestsSetup: Bool
    let createdAt: String
}
