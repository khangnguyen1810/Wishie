import Testing
import Foundation
@testable import Wishie

struct HomeCardSummaryTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 26, hour: 15))!

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: today)!
    }

    private func wishlist(
        id: String = "w",
        due: Int = 10,
        items: [WishlistItem] = [],
        owner: String = "owner"
    ) -> WishlistModel {
        WishlistModel(id: id, name: id, dueDate: day(due), items: items, userCreateId: owner, members: [owner: .owner])
    }

    // MARK: - Top wish and mosaic

    @Test func topItemIsTheMostDesiredItem() {
        let items = [WishlistItem(id: "a"), WishlistItem(id: "b", isMostDesired: true), WishlistItem(id: "c")]
        let summary = HomeCardSummary(wishlist: wishlist(items: items), currentUserId: "me")
        #expect(summary.topItem?.id == "b")
        #expect(summary.isTopItemMostDesired)
        #expect(summary.otherItems.map(\.id) == ["a", "c"])
    }

    @Test func topItemFallsBackToTheFirstItem() {
        let items = [WishlistItem(id: "a"), WishlistItem(id: "b")]
        let summary = HomeCardSummary(wishlist: wishlist(items: items), currentUserId: "me")
        #expect(summary.topItem?.id == "a")
        #expect(summary.isTopItemMostDesired == false)
        #expect(summary.otherItems.map(\.id) == ["b"])
    }

    @Test func extraCountIsWhatTheThreeTileMosaicCannotShow() {
        let items = (0..<14).map { WishlistItem(id: "\($0)") }
        #expect(HomeCardSummary(wishlist: wishlist(items: items), currentUserId: "me").extraCount == 11)
        let few = (0..<3).map { WishlistItem(id: "\($0)") }
        #expect(HomeCardSummary(wishlist: wishlist(items: few), currentUserId: "me").extraCount == 0)
    }

    @Test func pickedByMeOnlyMatchesTheCurrentUser() {
        let mine = WishlistItem(id: "a", pickedUserId: "me", isPicked: true)
        let theirs = WishlistItem(id: "b", pickedUserId: "other", isPicked: true)
        let summary = HomeCardSummary(wishlist: wishlist(items: [mine, theirs]), currentUserId: "me")
        #expect(summary.isPickedByMe(mine))
        #expect(summary.isPickedByMe(theirs) == false)
        #expect(HomeCardSummary(wishlist: wishlist(items: [mine]), currentUserId: nil).isPickedByMe(mine) == false)
    }

    // MARK: - Status line

    @Test func ownerStatusCountsPickedGifts() {
        let items = [WishlistItem(isPicked: true), WishlistItem(isPicked: true), WishlistItem(), WishlistItem(), WishlistItem()]
        let summary = HomeCardSummary(wishlist: wishlist(items: items), currentUserId: "me")
        #expect(summary.statusText(isOwnList: true) == "2 of 5 picked")
        #expect(summary.statusText(isOwnList: false) == "3 of 5 still free")
    }

    @Test func statusWithoutItemsSaysNoGiftsYet() {
        let summary = HomeCardSummary(wishlist: wishlist(), currentUserId: "me")
        #expect(summary.statusText(isOwnList: true) == "No gifts yet")
        #expect(summary.statusText(isOwnList: false) == "No gifts yet")
    }

    // MARK: - Countdown

    @Test func countdownCountsWholeDays() {
        let summary = HomeCardSummary(wishlist: wishlist(due: 30), currentUserId: "me")
        let countdown = summary.countdown(today: today, calendar: calendar)
        #expect(countdown == .daysLeft(30))
        #expect(countdown.value == "30")
        #expect(countdown.caption == "days left")
        #expect(countdown.short == "30d")
    }

    @Test func countdownSingularDay() {
        let countdown = HomeCardSummary(wishlist: wishlist(due: 1), currentUserId: "me").countdown(today: today, calendar: calendar)
        #expect(countdown.caption == "day left")
    }

    @Test func countdownTodayAndPast() {
        let todayCountdown = HomeCardSummary(wishlist: wishlist(due: 0), currentUserId: "me").countdown(today: today, calendar: calendar)
        #expect(todayCountdown == .today)
        #expect(todayCountdown.value == "Today!")
        #expect(todayCountdown.short == "Today")
        let past = HomeCardSummary(wishlist: wishlist(due: -3), currentUserId: "me").countdown(today: today, calendar: calendar)
        #expect(past == .past)
        #expect(past.short == "Past")
    }

    // MARK: - Owner line

    @Test func ownerFirstNamePrefersTheProfile() {
        var model = wishlist()
        model.ownerName = "Fallback"
        #expect(HomeCardSummary.ownerFirstName(profile: UserModel(dictionary: ["firstName": "Minh"]), wishlist: model) == "Minh")
        #expect(HomeCardSummary.ownerFirstName(profile: UserModel(), wishlist: model) == "Fallback")
    }

    // MARK: - Featured card

    @Test func featuredIsTheNearestUpcomingWishlist() {
        let lists = [wishlist(id: "far", due: 80), wishlist(id: "past", due: -2), wishlist(id: "soon", due: 5)]
        let split = HomeCardSummary.splitFeatured(lists, today: today, calendar: calendar) { $0 }
        #expect(split.featured?.id == "soon")
        #expect(split.rest.map(\.id) == ["far", "past"])
    }

    @Test func featuredFallsBackToTheFirstWhenNothingIsUpcoming() {
        let lists = [wishlist(id: "a", due: -5), wishlist(id: "b", due: -1)]
        let split = HomeCardSummary.splitFeatured(lists, today: today, calendar: calendar) { $0 }
        #expect(split.featured?.id == "a")
        #expect(split.rest.map(\.id) == ["b"])
        #expect(HomeCardSummary.splitFeatured([WishlistModel](), today: today, calendar: calendar) { $0 }.featured == nil)
    }

    // MARK: - Header subtitle

    @Test func myListSubtitleCountsUpcomingWishlists() {
        let mine = [wishlist(id: "a", due: 3), wishlist(id: "b", due: 40), wishlist(id: "c", due: -1)]
        #expect(HomeCardSummary.subtitle(isMyList: true, mine: mine, friends: [], today: today, calendar: calendar) == "2 wishlists coming up")
        #expect(HomeCardSummary.subtitle(isMyList: true, mine: [wishlist(due: 0)], friends: [], today: today, calendar: calendar) == "1 wishlist coming up")
        #expect(HomeCardSummary.subtitle(isMyList: true, mine: [], friends: [], today: today, calendar: calendar) == "What are you wishing for?")
    }

    @Test func friendsSubtitleCountsDistinctOwners() {
        let friends = [wishlist(id: "a", owner: "minh"), wishlist(id: "b", owner: "minh"), wishlist(id: "c", owner: "linh")]
        #expect(HomeCardSummary.subtitle(isMyList: false, mine: [], friends: friends, today: today, calendar: calendar) == "2 friends are wishing")
        #expect(HomeCardSummary.subtitle(isMyList: false, mine: [], friends: [wishlist(owner: "minh")], today: today, calendar: calendar) == "1 friend is wishing")
    }

    @Test func friendsSubtitleFallsBackToMyListCopyWhenEmpty() {
        let mine = [wishlist(id: "a", due: 3), wishlist(id: "b", due: 4)]
        #expect(HomeCardSummary.subtitle(isMyList: false, mine: mine, friends: [], today: today, calendar: calendar) == "2 wishlists coming up")
    }
}
