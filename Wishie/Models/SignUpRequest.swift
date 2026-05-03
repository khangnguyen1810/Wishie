//
//  Models.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 12/10/25.
//

import Foundation

struct SignUpRequest {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var dateOfBirth: Date = Date()
}
