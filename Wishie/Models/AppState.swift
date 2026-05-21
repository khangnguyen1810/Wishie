import Foundation

enum AppState: Hashable {
    case welcome
    case unauthenticated
    case authenticated(userId: String)

    var requiresAuthentication: Bool {
        switch self {
        case .unauthenticated:
            return true
        case .welcome, .authenticated:
            return false
        }
    }
}
