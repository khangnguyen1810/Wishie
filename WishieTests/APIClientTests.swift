import Testing
import Foundation
@testable import Wishie

@Suite(.serialized)
struct APIClientTests {
    private func seededKeychain(accessToken: String = "expired-token", refreshToken: String = "refresh-token") -> InMemoryKeychain {
        let keychain = InMemoryKeychain()
        keychain.save(key: "wishie.auth.accessToken", value: accessToken)
        keychain.save(key: "wishie.auth.refreshToken", value: refreshToken)
        keychain.save(key: "wishie.auth.userId", value: "user-1")
        keychain.save(key: "wishie.auth.email", value: "user@example.com")
        return keychain
    }

    @Test func sendDecodesASuccessfulJSONResponse() async throws {
        struct Sample: Decodable, Equatable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result: Sample = try await client.send(.get("/sample", requiresAuth: false))

        #expect(result == Sample(value: "ok"))
    }

    @Test func sendAttachesBearerTokenForAuthenticatedEndpoints() async throws {
        struct Sample: Decodable { let value: String }
        var capturedAuthHeader: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let keychain = seededKeychain(accessToken: "valid-token")
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: keychain))

        let _: Sample = try await client.send(.get("/profiles/me"))

        #expect(capturedAuthHeader == "Bearer valid-token")
    }

    @Test func sendThrowsServerErrorWithDecodedMessage() async throws {
        struct Sample: Decodable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"statusCode":400,"message":"Invalid email","error":"Bad Request"}"#.utf8)
            return (response, body)
        }
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        do {
            let _: Sample = try await client.send(.post("/auth/signup", json: Data()))
            Issue.record("expected APIError.server to be thrown")
        } catch let error as APIError {
            #expect(error == .server(statusCode: 400, message: "Invalid email", code: nil))
        }
    }

    @Test func on401ClientRefreshesThenRetriesTheOriginalRequestOnce() async throws {
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
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: sessionStore)

        let result: Sample = try await client.send(.get("/profiles/me"))

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
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: sessionStore)

        do {
            let _: Sample = try await client.send(.get("/profiles/me"))
            Issue.record("expected APIError.sessionExpired to be thrown")
        } catch let error as APIError {
            #expect(error == .sessionExpired)
        }
        let cleared = await sessionStore.current()
        #expect(cleared == nil)
    }

    @Test func uploadMultipartEndpointSendsFileFieldsAndDecodesResponse() async throws {
        struct AvatarResponse: Decodable { let avatarUrl: String }
        var capturedContentType: String?
        var capturedBodyContainsFileBytes = false
        let fileData = Data([0xFF, 0xD8, 0xFF])
        MockURLProtocol.requestHandler = { request in
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
            // Read body from either httpBody or httpBodyStream (URLSession may convert)
            let body: Data?
            if let httpBody = request.httpBody {
                body = httpBody
            } else if let httpBodyStream = request.httpBodyStream {
                var streamData = Data()
                let bufferSize = 4096
                var buffer = [UInt8](repeating: 0, count: bufferSize)
                httpBodyStream.open()
                while httpBodyStream.hasBytesAvailable {
                    let bytesRead = httpBodyStream.read(&buffer, maxLength: bufferSize)
                    if bytesRead > 0 {
                        streamData.append(&buffer, count: bytesRead)
                    } else {
                        break
                    }
                }
                httpBodyStream.close()
                body = streamData
            } else {
                body = nil
            }
            capturedBodyContainsFileBytes = body.map { $0.range(of: fileData) != nil } ?? false
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"avatarUrl":"https://cdn.example.com/u1.jpg"}"#.utf8))
        }
        let keychain = seededKeychain(accessToken: "valid-token")
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: keychain))

        let endpoint = Endpoint.postMultipart("/profiles/me/avatar", fieldName: "file", fileName: "u1.jpg", mimeType: "image/jpeg", fileData: fileData)
        let result: AvatarResponse = try await client.send(endpoint)

        #expect(result.avatarUrl == "https://cdn.example.com/u1.jpg")
        #expect(capturedContentType?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(capturedBodyContainsFileBytes)
    }

    @Test func sendNoContentSucceedsWithoutDecodingABody() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"success":true}"#.utf8))
        }
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await client.sendNoContent(.post("/auth/logout", json: Data(), requiresAuth: false))
    }

    @Test func on401UnauthenticatedEndpointThrowsUnauthorizedWithoutRefresh() async throws {
        struct Sample: Decodable { let value: String }
        let keychain = seededKeychain(accessToken: "valid-token", refreshToken: "refresh-token")
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            // All requests should be the original login attempt (no refresh)
            if request.url!.path == "/auth/refresh" {
                Issue.record("refresh should not be called for requiresAuth: false endpoint")
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"statusCode":401,"message":"Invalid email or password","error":"Unauthorized"}"#.utf8)
            return (response, body)
        }
        let sessionStore = SessionStore(keychain: keychain)
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: sessionStore)

        do {
            let _: Sample = try await client.send(.post("/auth/login", json: Data(), requiresAuth: false))
            Issue.record("expected APIError.unauthorized to be thrown")
        } catch let error as APIError {
            #expect(error == .unauthorized)
        }
        #expect(callCount == 1) // only the original login attempt, no refresh retry
    }
}
