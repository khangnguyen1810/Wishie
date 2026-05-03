//
//  DateExtension.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 3/3/26.
//

import Foundation

extension Date {
    
    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, yy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    func toShortDateString() -> String {
        return Self.shortFormatter.string(from: self)
    }
}
