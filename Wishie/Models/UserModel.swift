//
//  UserModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 3/3/26.
//

import Foundation
struct UserModel: Codable, Hashable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var dateOfBirth: Date = Date()
    
    init(dictionary: [String: Any] = [:]) {
        self.firstName = dictionary["firstName"] as? String ?? ""
        self.lastName = dictionary["lastName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.phone = dictionary["phone"] as? String ?? ""
    }
    func getFullName() -> String {
        return "\(firstName) \(lastName)"
    }
}
