import Testing
import Foundation
@testable import Wishie

extension MockURLProtocolSharingTests {
    @Suite
    struct APIServiceTests {
    private func seededKeychain(accessToken: String = "expired-token", refreshToken: String = "refresh-token") -> InMemoryKeychain {
        let keychain = InMemoryKeychain()
        keychain.save(key: "wishie.auth.accessToken", value: accessToken)
        keychain.save(key: "wishie.auth.refreshToken", value: refreshToken)
        keychain.save(key: "wishie.auth.userId", value: "user-1")
        keychain.save(key: "wishie.auth.email", value: "user@example.com")
        return keychain
    }

    private func makeConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }

    @Test func sendDecodesASuccessfulJSONResponse() async throws {
        struct Sample: Decodable, Equatable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        let result: Sample = try await service.send(.getWishlists)

        #expect(result == Sample(value: "ok"))
    }

    @Test func sendAttachesBearerTokenForAuthenticatedRoutes() async throws {
        struct Sample: Decodable { let value: String }
        var capturedAuthHeader: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        let _: Sample = try await service.send(.getProfile(id: "u1"))

        #expect(capturedAuthHeader == "Bearer valid-token")
    }

    @Test func sendDoesNotAttachBearerTokenForUnauthenticatedRoutes() async throws {
        struct Sample: Decodable { let value: String }
        var capturedAuthHeader: String? = "not-yet-set"
        MockURLProtocol.requestHandler = { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let _: Sample = try await service.send(.login(email: "a@b.com", password: "pw"))

        #expect(capturedAuthHeader == nil)
    }

    @Test func sendThrowsServerErrorWithDecodedMessage() async throws {
        struct Sample: Decodable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"statusCode":400,"message":"Invalid id","error":"Bad Request"}"#.utf8)
            return (response, body)
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        do {
            let _: Sample = try await service.send(.getProfile(id: "u1"))
            Issue.record("expected APIError.server to be thrown")
        } catch let error as APIError {
            #expect(error == .server(statusCode: 400, message: "Invalid id", code: nil))
        }
    }

    @Test func on401ItRefreshesThenRetriesTheOriginalRequestOnce() async throws {
        struct Sample: Decodable { let value: String }
        let keychain = seededKeychain(accessToken: "expired-token", refreshToken: "refresh-token")
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if request.url!.path == "/auth/refresh" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
                let body = Data(#"{"accessToken":"new-token","refreshToken":"new-refresh","userId":"user-1","email":"user@example.com"}"#.utf8)
                return (response, body)
            }
            if request.value(forHTTPHeaderField: "Authorization") == "Bearer expired-token" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer new-token")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let sessionStore = SessionStore(keychain: keychain)
        let service = APIService(configuration: makeConfiguration(), sessionStore: sessionStore)

        let result: Sample = try await service.send(.getWishlists)

        #expect(result.value == "ok")
        #expect(callCount == 3) // original 401 + refresh + retry
        let refreshed = await sessionStore.current()
        #expect(refreshed?.accessToken == "new-token")
    }

    @Test func whenRefreshFailsSessionIsClearedAndSessionExpiredIsThrown() async throws {
        struct Sample: Decodable { let value: String }
        let keychain = seededKeychain(accessToken: "expired-token", refreshToken: "bad-refresh")
        MockURLProtocol.requestHandler = { request in
            if request.url!.path == "/auth/refresh" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let body = Data(#"{"statusCode":401,"code":"AUTH_REFRESH_TOKEN_INVALID","message":"Invalid Refresh Token"}"#.utf8)
                return (response, body)
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let sessionStore = SessionStore(keychain: keychain)
        let service = APIService(configuration: makeConfiguration(), sessionStore: sessionStore)

        do {
            let _: Sample = try await service.send(.getWishlists)
            Issue.record("expected APIError.sessionExpired to be thrown")
        } catch let error as APIError {
            #expect(error == .sessionExpired)
        }
        let cleared = await sessionStore.current()
        #expect(cleared == nil)
    }

    @Test func on401ForAnUnauthenticatedRouteThrowsWithoutAttemptingRefresh() async throws {
        struct Sample: Decodable { let value: String }
        let keychain = seededKeychain(accessToken: "valid-token", refreshToken: "refresh-token")
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if request.url!.path == "/auth/refresh" {
                Issue.record("refresh should not be called for an unauthenticated route")
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"statusCode":401,"message":"Invalid email or password","error":"Unauthorized"}"#.utf8)
            return (response, body)
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: keychain))

        do {
            let _: Sample = try await service.send(.login(email: "a@b.com", password: "wrong"))
            Issue.record("expected APIError.unauthorized to be thrown")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                Issue.record("expected APIError.unauthorized, got \(error)")
                return
            }
        }
        #expect(callCount == 1) // only the original login attempt, no refresh retry
    }

    @Test func sendDispatchesMultipartRoutesAsAnUploadRequest() async throws {
        struct Sample: Decodable { let id: String }
        var capturedContentType: String?
        var capturedAuthHeader: String?
        MockURLProtocol.requestHandler = { request in
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"id":"i1"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        let result: Sample = try await service.send(.uploadItemImage(wishlistId: "w1", itemId: "i1", imageData: Data([0xFF, 0xD8, 0xFF])))

        #expect(result.id == "i1")
        #expect(capturedContentType?.hasPrefix("multipart/form-data") == true)
        #expect(capturedAuthHeader == "Bearer valid-token")
    }

    @Test func sendMapsAdaptationFailureToSessionExpiredWithoutSendingARequest() async throws {
        struct Sample: Decodable { let value: String }
        MockURLProtocol.requestHandler = { _ in
            Issue.record("request should never be sent")
            let response = HTTPURLResponse(url: URL(string: "http://localhost:3000")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: InMemoryKeychain()))

        do {
            let _: Sample = try await service.send(.getWishlists)
            Issue.record("expected APIError.sessionExpired to be thrown")
        } catch let error as APIError {
            #expect(error == .sessionExpired)
        }
    }
    }
}
