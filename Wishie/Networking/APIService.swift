import Alamofire
import Foundation

protocol APIServiceProtocol {
    func send<T: Decodable>(_ route: APIRoute) async throws -> T
}

final class APIService: APIServiceProtocol {
    private let session: Alamofire.Session

    init(configuration: URLSessionConfiguration = .default, sessionStore: SessionStore = .shared) {
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
