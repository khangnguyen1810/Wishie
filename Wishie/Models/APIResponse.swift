import Foundation

struct WishlistMemberProfileResponse: Decodable {
    let firstName: String
    let lastName: String
    let email: String
    let avatarUrl: String?
}

struct WishlistMemberResponse: Decodable {
    let wishlistId: String
    let userId: String
    let role: String   // "owner" | "member"
    let joinedAt: String
    let profile: WishlistMemberProfileResponse?

    init(wishlistId: String, userId: String, role: String, joinedAt: String, profile: WishlistMemberProfileResponse? = nil) {
        self.wishlistId = wishlistId
        self.userId = userId
        self.role = role
        self.joinedAt = joinedAt
        self.profile = profile
    }
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

struct WishlistImageUploadResponse: Decodable {
    let imageUrl: String
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
    let ownerName: String?
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

struct WishlistInfoResponse: Decodable {
    let id: String
    let name: String
    let description: String
    let dueDate: String
    let colorTheme: String?
    let itemCount: Int
}
