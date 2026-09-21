import Testing
import Foundation
import Alamofire
@testable import Wishie

struct APIRouteTests {
    @Test func getWishlistsBuildsAnAuthenticatedGETRequest() throws {
        let request = try APIRoute.getWishlists.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/wishlists")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
    }

    @Test func getProfileBuildsPathWithTheGivenId() throws {
        let request = try APIRoute.getProfile(id: "u2").asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/profiles/u2")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
    }

    @Test func refreshBuildsAnUnauthenticatedPOSTWithTheRefreshTokenBody() throws {
        let request = try APIRoute.refresh(refreshToken: "r1").asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/refresh")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == nil)
        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json?["refreshToken"] == "r1")
    }

    @Test func loginBuildsAnUnauthenticatedPOSTWithCredentials() throws {
        let request = try APIRoute.login(email: "a@b.com", password: "pw").asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/login")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == nil)
        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json?["email"] == "a@b.com")
        #expect(json?["password"] == "pw")
    }

    @Test func signupBuildsAnUnauthenticatedPOSTWithProfileFields() throws {
        var signUp = SignUpRequest()
        signUp.firstName = "Ada"
        signUp.lastName = "Lovelace"
        signUp.email = "ada@example.com"
        signUp.phone = "123"
        signUp.password = "password1"
        signUp.dateOfBirth = WishieDateFormatting.dateOnly.date(from: "1990-01-01")!

        let request = try APIRoute.signup(signUp).asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/signup")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == nil)
        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json?["email"] == "ada@example.com")
        #expect(json?["dateOfBirth"] == "1990-01-01")
    }

    @Test func createWishlistBuildsAnAuthenticatedPOSTWithTheWishlistBody() throws {
        let item = WishlistItem(id: "i1", name: "Lego", itemLink: "https://shop.example.com", price: "19.99")
        let wishlist = WishlistModel(id: "w1", name: "Birthday", dueDate: Date(), items: [item], userCreateId: "u1")
        let body = CreateWishlistRequest(wishlist)

        let request = try APIRoute.createWishlist(body).asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/wishlists")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
        let httpBody = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: httpBody) as? [String: Any]
        #expect(json?["id"] as? String == "w1")
        #expect(json?["name"] as? String == "Birthday")
    }

    @Test func uploadItemImageBuildsAnAuthenticatedPATCHWithNoJSONBody() throws {
        let request = try APIRoute.uploadItemImage(wishlistId: "w1", itemId: "i1", imageData: Data([0x01])).asURLRequest()

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path == "/wishlists/w1/items/i1")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
        #expect(request.httpBody == nil)
    }

    @Test func uploadItemImageMultipartFormDataAppendsTheImageAsAFileField() throws {
        let imageData = Data([0xFF, 0xD8, 0xFF])
        let route = APIRoute.uploadItemImage(wishlistId: "w1", itemId: "i1", imageData: imageData)
        let form = MultipartFormData()

        route.multipartFormData?(form)
        let encoded = try form.encode()
        let encodedString = String(decoding: encoded, as: UTF8.self)

        #expect(encodedString.contains("name=\"file\""))
        #expect(encodedString.contains("filename=\"image.jpg\""))
        #expect(encodedString.contains("Content-Type: image/jpeg"))
    }

    @Test func nonUploadRoutesHaveNoMultipartFormData() {
        #expect(APIRoute.getWishlists.multipartFormData == nil)
    }
}
