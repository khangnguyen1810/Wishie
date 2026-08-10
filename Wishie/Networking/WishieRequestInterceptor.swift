import Alamofire
import Foundation

/// Attaches the bearer token from `SessionStore` to routes marked via `APIRoute.requiresAuthHeader`,
/// and retries once (after a token refresh) on a 401 — but only for requests that actually carried
/// an `Authorization` header, so an unauthenticated route's own 401 (e.g. bad login credentials)
/// isn't mistaken for an expired session.
final class WishieRequestInterceptor: RequestInterceptor {
    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard urlRequest.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true" else {
            completion(.success(urlRequest))
            return
        }
        Task {
            var request = urlRequest
            request.setValue(nil, forHTTPHeaderField: APIRoute.requiresAuthHeader)
            guard let token = await sessionStore.current()?.accessToken else {
                completion(.failure(APIError.sessionExpired))
                return
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            completion(.success(request))
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // The `request.request?.value(forHTTPHeaderField: "Authorization") != nil` check below is also
        // what prevents the refresh sub-request dispatched from this method from recursively triggering
        // another refresh: `.refresh` has `requiresAuth == false` and never carries a bearer token, so it
        // never satisfies this guard, regardless of which interceptor instance handles its `adapt`/`retry`.
        guard let statusCode = (request.task?.response as? HTTPURLResponse)?.statusCode,
              statusCode == 401,
              request.request?.value(forHTTPHeaderField: "Authorization") != nil,
              request.retryCount < 1 else {
            completion(.doNotRetry)
            return
        }
        Task {
            do {
                _ = try await sessionStore.refreshedSession { refreshToken in
                    let dataResponse = await session.request(APIRoute.refresh(refreshToken: refreshToken))
                        .validate()
                        .serializingDecodable(AuthSession.self)
                        .response
                    switch dataResponse.result {
                    case .success(let authSession):
                        return authSession
                    case .failure(let error):
                        throw APIError.transport(error.localizedDescription)
                    }
                }
                completion(.retry)
            } catch {
                completion(.doNotRetryWithError(APIError.sessionExpired))
            }
        }
    }
}
