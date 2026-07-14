import Testing
@testable import Wishie

struct MostDesiredRuleTests {

    private func items() -> [[String: Any]] {
        [
            ["id": "a", "isMostDesired": true],
            ["id": "b", "isMostDesired": false],
            ["id": "c", "isMostDesired": false]
        ]
    }

    private func isMostDesired(_ items: [[String: Any]], _ id: String) -> Bool {
        items.first { $0["id"] as? String == id }?["isMostDesired"] as? Bool ?? false
    }

    @Test func markingAnItemClearsThePreviousMostDesired() {
        let result = MostDesiredRule.apply(items: items(), itemId: "b", isMostDesired: true)

        #expect(isMostDesired(result, "b") == true)
        #expect(isMostDesired(result, "a") == false)
        #expect(isMostDesired(result, "c") == false)
    }

    @Test func atMostOneItemIsEverMostDesired() {
        let result = MostDesiredRule.apply(items: items(), itemId: "c", isMostDesired: true)

        let desiredCount = result.filter { $0["isMostDesired"] as? Bool == true }.count
        #expect(desiredCount == 1)
    }

    @Test func unmarkingClearsOnlyTheTargetAndLeavesOthersAlone() {
        let result = MostDesiredRule.apply(items: items(), itemId: "a", isMostDesired: false)

        let desiredCount = result.filter { $0["isMostDesired"] as? Bool == true }.count
        #expect(desiredCount == 0)
    }

    @Test func markingAnAlreadyDesiredItemIsIdempotent() {
        let result = MostDesiredRule.apply(items: items(), itemId: "a", isMostDesired: true)

        #expect(isMostDesired(result, "a") == true)
        let desiredCount = result.filter { $0["isMostDesired"] as? Bool == true }.count
        #expect(desiredCount == 1)
    }

    @Test func itemsWithoutAnIdArePreserved() {
        var withMalformed = items()
        withMalformed.append(["isMostDesired": false])

        let result = MostDesiredRule.apply(items: withMalformed, itemId: "b", isMostDesired: true)

        #expect(result.count == 4)
        #expect(isMostDesired(result, "b") == true)
    }
}
