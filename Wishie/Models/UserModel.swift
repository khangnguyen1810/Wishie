//
//  UserModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 3/3/26.
//

import Foundation
import FirebaseFirestore

struct UserModel: Codable, Hashable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var dateOfBirth: Date = Date()
    var avatarUrl: String? = nil
    var interests: [String] = []
    var hasCompletedInterestsSetup: Bool = false
    
    init(dictionary: [String: Any] = [:]) {
        self.firstName = dictionary["firstName"] as? String ?? ""
        self.lastName = dictionary["lastName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.phone = dictionary["phone"] as? String ?? ""
        if let timestamp = dictionary["dateOfBirth"] as? Timestamp {
            self.dateOfBirth = timestamp.dateValue()
        }
        self.avatarUrl = dictionary["avatarUrl"] as? String
        self.interests = dictionary["interests"] as? [String] ?? []
        self.hasCompletedInterestsSetup = dictionary["hasCompletedInterestsSetup"] as? Bool ?? false
    }
    func getFullName() -> String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

extension UserModel {
    init(profile: ProfileResponse) {
        self.init()
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.email = profile.email
        self.phone = profile.phone
        if let dateOfBirthString = profile.dateOfBirth, let date = WishieDateFormatting.parseServerDate(dateOfBirthString) {
            self.dateOfBirth = date
        }
        self.avatarUrl = profile.avatarUrl
        self.interests = profile.interests
        self.hasCompletedInterestsSetup = profile.hasCompletedInterestsSetup
    }
}
