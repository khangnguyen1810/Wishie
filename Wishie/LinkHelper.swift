//
//  LinkHelper.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 19/12/25.
//

import Foundation
import UIKit
enum ProductLinkHelper {
    static func openURL(_ url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url)
    }
    static func host(from url: String) -> String? {
        URL(string: url)?.host()
    }
}
