import Foundation

enum AppState: Hashable {
    case welcome
    case unauthenticated
    case interestsSetup
    case authenticated(userId: String)

    var requiresAuthentication: Bool {
        switch self {
        case .unauthenticated:
            return true
        case .welcome, .interestsSetup, .authenticated:
            return false
        }
    }
}
