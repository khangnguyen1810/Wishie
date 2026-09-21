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
    case getWishlistInfoByCode(code: String)
    case getProfile(id: String)
    case createWishlist(CreateWishlistRequest)
    case uploadItemImage(wishlistId: String, itemId: String, imageData: Data)
    case uploadWishlistImage(wishlistId: String, imageData: Data)
    case editWishlistItem(wishlistId: String, itemId: String, wishItem: EditWishlistItemRequest)
    case getDetailWishlist(wishlistId: String)
    case markItemDesired(wishlistId: String, itemId: String, isMostDesired: Bool)
    var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile, .getDetailWishlist, .getWishlistInfoByCode: return .get
        case .login, .signup, .refresh, .createWishlist, .uploadWishlistImage: return .post
        case .uploadItemImage, .editWishlistItem, .markItemDesired: return .patch
        }
    }

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .signup: return "/auth/signup"
        case .refresh: return "/auth/refresh"
        case .getWishlists: return "/wishlists"
        case .getProfile(let id): return "/profiles/\(id)"
        case .createWishlist: return "/wishlists"
        case .uploadItemImage(let wishlistId, let itemId, _): return "/wishlists/\(wishlistId)/items/\(itemId)"
        case .uploadWishlistImage(let wishlistId, _): return "/wishlists/\(wishlistId)/items/image"
        case .editWishlistItem(let wishlistId, let wishListItemId, _): return "/wishlists/\(wishlistId)/items/\(wishListItemId)"
        case .getDetailWishlist(let wishlistId): return "/wishlists/\(wishlistId)"
        case .markItemDesired(let wishlistId, let itemId, _): return "/wishlists/\(wishlistId)/items/\(itemId)/most-desired"
        case .getWishlistInfoByCode(let code): return "/wishlists/join/\(code)"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists,
                .getProfile,
                .createWishlist,
                .uploadItemImage,
                .uploadWishlistImage,
                .editWishlistItem,
                .getDetailWishlist,
                .markItemDesired,
                .getWishlistInfoByCode: return true
        }
    }

    /// Non-`nil` only for multipart routes. `APIService.send` checks this to decide whether to
    /// dispatch via `session.upload(multipartFormData:with:)` instead of `session.request(_:)`.
    var multipartFormData: ((MultipartFormData) -> Void)? {
        switch self {
        case .uploadItemImage(_, _, let imageData), .uploadWishlistImage(_, let imageData):
            return { form in
                form.append(imageData, withName: "file", fileName: "image.jpg", mimeType: "image/jpeg")
            }
        default:
            return nil
        }
    }

    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        if requiresAuth {
            request.setValue("true", forHTTPHeaderField: Self.requiresAuthHeader)
        }
        // Multipart routes have no JSON body — Alamofire sets the multipart `Content-Type`
        // (with boundary) itself when `APIService.send` encodes `multipartFormData`.
        if case .uploadItemImage = self {
            return request
        }
        if case .uploadWishlistImage = self {
            return request
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
        case .createWishlist(let body):
            request.httpBody = try JSONEncoder().encode(body)
            return request
        case .getWishlists, .getProfile, .uploadItemImage, .uploadWishlistImage, .getDetailWishlist, .getWishlistInfoByCode:
            return request
        case .editWishlistItem(_, _, let body):
            request.httpBody = try JSONEncoder().encode(body)
            return request
        case .markItemDesired(_, _, let isMostDesired):
            return try JSONEncoding.default.encode(request, with: ["isMostDesired": isMostDesired])
        }
    }
}
