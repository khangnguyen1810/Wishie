import Foundation

protocol APIClientProtocol {
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func sendNoContent(_ endpoint: Endpoint) async throws
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let sessionStore: SessionStore

    /// A shorter-than-default timeout so a slow/unreachable backend can't block the UI (e.g. a
    /// blocking progress overlay during logout) for the system default of 60 seconds.
    private static let defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        return URLSession(configuration: config)
    }()

    init(session: URLSession = APIClient.defaultSession, baseURL: URL = APIConfig.baseURL, sessionStore: SessionStore = .shared) {
        self.session = session
        self.baseURL = baseURL
        self.sessionStore = sessionStore
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await executeWithRefresh(endpoint)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    func sendNoContent(_ endpoint: Endpoint) async throws {
        _ = try await executeWithRefresh(endpoint)
    }

    private func executeWithRefresh(_ endpoint: Endpoint) async throws -> Data {
        do {
            return try await execute(endpoint)
        } catch let error as APIError {
            guard case .unauthorized = error else { throw error }
            guard endpoint.requiresAuth else { throw error }
            _ = try await sessionStore.refreshedSession { [weak self] refreshToken in
                guard let self else { throw APIError.sessionExpired }
                return try await self.performRefresh(refreshToken: refreshToken)
            }
            return try await execute(endpoint)
        }
    }

    private func performRefresh(refreshToken: String) async throws -> AuthSession {
        struct RefreshBody: Encodable { let refreshToken: String }
        let json = try JSONEncoder().encode(RefreshBody(refreshToken: refreshToken))
        let data = try await execute(.post("/auth/refresh", json: json, requiresAuth: false))
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func execute(_ endpoint: Endpoint) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method

        switch endpoint.body {
        case .json(let data):
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .multipart(let fieldName, let fileName, let mimeType, let fileData):
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        case .none:
            break
        }

        if endpoint.requiresAuth {
            guard let token = await sessionStore.current()?.accessToken else {
                throw APIError.sessionExpired
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if http.statusCode == 401 {
            throw APIError.unauthorized(APIError.decodeServerError(data: data, statusCode: http.statusCode))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.decodeServerError(data: data, statusCode: http.statusCode)
        }
        return data
    }
}
