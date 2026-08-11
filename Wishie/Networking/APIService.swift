import Alamofire
import Foundation

protocol APIServiceProtocol {
    func send<T: Decodable>(_ route: APIRoute) async throws -> T
}

final class APIService: APIServiceProtocol {
    private let session: Alamofire.Session

    /// A shorter-than-default timeout so a slow/unreachable backend can't block the UI (e.g.
    /// Home's blocking full-screen overlay while `isGettingList`/`isLoading` is true) for the
    /// system default of 60 seconds. Mirrors `APIClient.defaultSession`'s timeout.
    static let defaultConfiguration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        return config
    }()

    init(configuration: URLSessionConfiguration = APIService.defaultConfiguration, sessionStore: SessionStore = .shared) {
        session = Alamofire.Session(configuration: configuration, interceptor: WishieRequestInterceptor(sessionStore: sessionStore))
    }

    func send<T: Decodable>(_ route: APIRoute) async throws -> T {
        let dataResponse = await session.request(route)
            .validate()
            .serializingData()
            .response

        if let afError = dataResponse.error {
            if case .requestRetryFailed(let retryError, _) = afError, let apiError = retryError as? APIError {
                throw apiError
            }
            if case .requestAdaptationFailed(let adaptError) = afError, let apiError = adaptError as? APIError {
                throw apiError
            }
            guard let httpResponse = dataResponse.response else {
                throw APIError.transport(afError.localizedDescription)
            }
            let data = dataResponse.data ?? Data()
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized(APIError.decodeServerError(data: data, statusCode: httpResponse.statusCode))
            }
            throw APIError.decodeServerError(data: data, statusCode: httpResponse.statusCode)
        }

        let data = dataResponse.data ?? Data()
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }
}
