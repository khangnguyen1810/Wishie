import Alamofire
import Foundation

enum APIRoute: URLRequestConvertible {
    /// A signal header `asURLRequest()` sets on routes that need a bearer token; `WishieRequestInterceptor`
    /// reads it in `adapt(_:for:completion:)` (where `SessionStore` is reachable, unlike here) and strips
    /// it before the request goes out. `asURLRequest()` itself can't be `async`, so it can't read
    /// `SessionStore` (an actor) directly.
    static let requiresAuthHeader = "X-Wishie-Requires-Auth"

    case login(email: String, password: String)
    case signup(SignUpRequest)
    case refresh(refreshToken: String)
    case getWishlists
    case getProfile(id: String)

    var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile: return .get
        case .login, .signup, .refresh: return .post
        }
    }

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .signup: return "/auth/signup"
        case .refresh: return "/auth/refresh"
        case .getWishlists: return "/wishlists"
        case .getProfile(let id): return "/profiles/\(id)"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists, .getProfile: return true
        }
    }

    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth {
            request.setValue("true", forHTTPHeaderField: Self.requiresAuthHeader)
        }
        switch self {
        case .login(let email, let password):
            return try JSONEncoding.default.encode(request, with: ["email": email, "password": password])
        case .signup(let body):
            return try JSONEncoding.default.encode(request, with: [
                "email": body.email,
                "password": body.password,
                "firstName": body.firstName,
                "lastName": body.lastName,
                "phone": body.phone,
                "dateOfBirth": WishieDateFormatting.dateOnly.string(from: body.dateOfBirth)
            ])
        case .refresh(let refreshToken):
            return try JSONEncoding.default.encode(request, with: ["refreshToken": refreshToken])
        case .getWishlists, .getProfile:
            return request
        }
    }
}
