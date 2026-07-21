import Testing
import Foundation
@testable import Wishie

struct GiftSuggestionInputBuilderTests {

    @Test func interestNamesMapsKnownIdsToHumanNames() {
        let names = GiftSuggestionInputBuilder.interestNames(fromIds: ["gaming", "reading"])
        #expect(names.contains("Gaming"))
        #expect(names.contains("Reading"))
        #expect(names.count == 2)
    }

    @Test func interestNamesDropsUnknownIds() {
        let names = GiftSuggestionInputBuilder.interestNames(fromIds: ["gaming", "not_a_real_id"])
        #expect(names == ["Gaming"])
    }

    @Test func ageComputesWholeYearsFromDateOfBirth() {
        let cal = Calendar(identifier: .gregorian)
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        let dob = cal.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        #expect(GiftSuggestionInputBuilder.age(from: dob, now: now) == 26)
    }

    @Test func existingItemNamesTrimsAndDropsEmpty() {
        let items = [
            WishlistItem(name: "  AirPods  "),
            WishlistItem(name: ""),
            WishlistItem(name: "Book")
        ]
        let names = GiftSuggestionInputBuilder.existingItemNames(from: items)
        #expect(names == ["AirPods", "Book"])
    }

    @Test func countryNameMapsIsoRegionCodeToEnglishName() {
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: "VN") == "Vietnam")
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: "US") == "United States")
    }

    @Test func countryNameReturnsNilForNilOrEmptyCode() {
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: nil) == nil)
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: "") == nil)
    }
}
