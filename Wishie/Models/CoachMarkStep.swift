import Foundation

struct CoachMarkStep {
    let anchorID: String?
    let title: String
    let message: String
    let arrowDirection: CoachMarkArrowDirection
}

enum CoachMarkArrowDirection {
    case up
    case down
    case none
}
