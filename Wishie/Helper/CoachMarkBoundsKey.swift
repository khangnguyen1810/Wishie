import SwiftUI

struct CoachMarkBoundsKey: PreferenceKey {
    typealias Value = [String: Anchor<CGRect>]

    static var defaultValue: Value = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
