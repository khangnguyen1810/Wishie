//
//  WishieDisplayFontTests.swift
//  WishieTests
//

import Testing
import UIKit

struct WishieDisplayFontTests {
    @Test func baloo2SemiBoldIsRegistered() {
        #expect(UIFont(name: "Baloo2-SemiBold", size: 12) != nil)
    }

    @Test func baloo2BoldIsRegistered() {
        #expect(UIFont(name: "Baloo2-Bold", size: 12) != nil)
    }

    @Test func baloo2ExtraBoldIsRegistered() {
        #expect(UIFont(name: "Baloo2-ExtraBold", size: 12) != nil)
    }
}
