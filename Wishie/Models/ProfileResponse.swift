import Foundation

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
