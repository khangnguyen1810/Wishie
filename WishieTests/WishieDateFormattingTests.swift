import Testing
import Foundation
@testable import Wishie

struct WishieDateFormattingTests {
    @Test func dateOnlyFormatsAsYYYYMMDD() {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        let date = calendar.date(from: components)!

        #expect(WishieDateFormatting.dateOnly.string(from: date) == "2000-01-01")
    }

    @Test func parseServerDateHandlesDateOnlyStrings() {
        #expect(WishieDateFormatting.parseServerDate("2000-01-01") != nil)
    }

    @Test func parseServerDateHandlesFullISODatetimeStrings() {
        #expect(WishieDateFormatting.parseServerDate("2026-08-07T10:00:00.000Z") != nil)
    }

    @Test func parseServerDateReturnsNilForGarbage() {
        #expect(WishieDateFormatting.parseServerDate("not-a-date") == nil)
    }
}
