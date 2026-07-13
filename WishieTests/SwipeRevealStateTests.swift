import Testing
@testable import Wishie

struct SwipeRevealStateTests {

    @Test func staysClosedForSmallDrag() {
        let state = swipeRevealState(baseOffset: 0, translation: -10, actionWidth: 92)
        #expect(state == .closed)
    }

    @Test func opensPastHalfActionWidth() {
        let state = swipeRevealState(baseOffset: 0, translation: -47, actionWidth: 92)
        #expect(state == .open)
    }

    @Test func closesWhenDraggedBackFromOpen() {
        let state = swipeRevealState(baseOffset: -92, translation: 50, actionWidth: 92)
        #expect(state == .closed)
    }

    @Test func staysOpenWithSmallReverseDrag() {
        let state = swipeRevealState(baseOffset: -92, translation: 10, actionWidth: 92)
        #expect(state == .open)
    }

    @Test func rightwardDragFromClosedStaysClosed() {
        let state = swipeRevealState(baseOffset: 0, translation: 40, actionWidth: 92)
        #expect(state == .closed)
    }
}
