import Testing
import Foundation
@testable import Wishie

struct WishieErrorTests {
    @Test func decodesGenericNestErrorShape() {
        let json = """
        {"statusCode":400,"message":"Invalid email","error":"Bad Request"}
        """.data(using: .utf8)!

        let error = WishieError.decodeServerError(data: json, statusCode: 400)

        #expect(error == .server(statusCode: 400, message: "Invalid email", error: "Bad Request"))
        #expect(error.statusCode == 400)
    }

    @Test func decodesRefreshLogoutErrorShapeWithCode() {
        let json = """
        {"statusCode":401,"code":"AUTH_REFRESH_TOKEN_INVALID","message":"Invalid Refresh Token"}
        """.data(using: .utf8)!

        let error = WishieError.decodeServerError(data: json, statusCode: 401)

        #expect(error == .server(statusCode: 401, message: "Invalid Refresh Token", code: "AUTH_REFRESH_TOKEN_INVALID"))
        #expect(error.code == "AUTH_REFRESH_TOKEN_INVALID")
    }

    @Test func decodesMessageArrayFromValidationErrors() {
        let json = """
        {"statusCode":400,"message":["email must be valid","password too short"],"error":"Bad Request"}
        """.data(using: .utf8)!

        let error = WishieError.decodeServerError(data: json, statusCode: 400)

        #expect(error == .server(statusCode: 400, message: "email must be valid\npassword too short", error: "Bad Request"))
    }

    @Test func decodesInternalServerErrorWithoutErrorField() {
        let json = """
        {"statusCode":500,"message":"Internal server error"}
        """.data(using: .utf8)!

        let error = WishieError.decodeServerError(data: json, statusCode: 500)

        #expect(error == .server(statusCode: 500, message: "Internal server error"))
        #expect(error.errorDescription == "Internal server error")
    }

    @Test func fallsBackToGenericMessageWhenBodyIsUnparseable() {
        let error = WishieError.decodeServerError(data: Data(), statusCode: 500)

        #expect(error == .server(statusCode: 500, message: "Unexpected error"))
    }

    @Test func wrappingPassesWishieErrorThrough() {
        #expect(WishieError(WishieError.sessionExpired) == .sessionExpired)
    }

    @Test func wrappingForeignErrorBecomesUnknown() {
        let foreign = NSError(domain: "Firestore", code: 7, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])

        #expect(WishieError(foreign) == .unknown("Permission denied"))
    }
}
