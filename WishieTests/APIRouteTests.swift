import Testing
import Foundation
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
}
