import Testing
import Foundation
@testable import Wishie

struct AuthSessionTests {
    @Test func decodesFromAPISignupResponseShape() throws {
        let json = """
        {
          "accessToken": "eyJhbGciOi...",
          "refreshToken": "v1.Mre...",
          "userId": "b3f1-uuid",
          "email": "user@example.com"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(AuthSession.self, from: json)

        #expect(session.accessToken == "eyJhbGciOi...")
        #expect(session.refreshToken == "v1.Mre...")
        #expect(session.userId == "b3f1-uuid")
        #expect(session.email == "user@example.com")
    }
}
