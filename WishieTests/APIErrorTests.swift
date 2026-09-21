import Testing
import Foundation
@testable import Wishie

struct APIErrorTests {
    @Test func decodesGenericNestErrorShape() {
        let json = """
        {"statusCode":400,"message":"Invalid email","error":"Bad Request"}
        """.data(using: .utf8)!

        let error = APIError.decodeServerError(data: json, statusCode: 400)

        #expect(error == .server(statusCode: 400, message: "Invalid email", code: nil))
    }

    @Test func decodesRefreshLogoutErrorShapeWithCode() {
        let json = """
        {"statusCode":401,"code":"AUTH_REFRESH_TOKEN_INVALID","message":"Invalid Refresh Token"}
        """.data(using: .utf8)!

        let error = APIError.decodeServerError(data: json, statusCode: 401)

        #expect(error == .server(statusCode: 401, message: "Invalid Refresh Token", code: "AUTH_REFRESH_TOKEN_INVALID"))
        #expect(error.code == "AUTH_REFRESH_TOKEN_INVALID")
    }

    @Test func decodesMessageArrayFromValidationErrors() {
        let json = """
        {"statusCode":400,"message":["email must be valid","password too short"],"error":"Bad Request"}
        """.data(using: .utf8)!

        let error = APIError.decodeServerError(data: json, statusCode: 400)

        #expect(error == .server(statusCode: 400, message: "email must be valid\npassword too short", code: nil))
    }

    @Test func fallsBackToGenericMessageWhenBodyIsUnparseable() {
        let error = APIError.decodeServerError(data: Data(), statusCode: 500)

        #expect(error == .server(statusCode: 500, message: "Unexpected error", code: nil))
    }
}
