import Foundation

/// The app-wide error type. Every service surfaces failures as `WishieError` so view models can
/// switch on a closed set of cases instead of casting an opaque `Error`.
enum WishieError: Error, LocalizedError, Equatable {
    /// A non-2xx response. Mirrors NestJS's default error body `{ statusCode, message, error? }`:
    /// `message` is joined with newlines when the backend sends an array (validation 400s), and
    /// `error` is the HTTP reason phrase (e.g. "Bad Request"), absent on unhandled 500s. `code` is
    /// the app-specific identifier a few routes add (e.g. `AUTH_REFRESH_TOKEN_INVALID`).
    case server(statusCode: Int, message: String, error: String? = nil, code: String? = nil)
    indirect case unauthorized(WishieError?)
    case sessionExpired
    case invalidResponse
    case transport(String)
    /// Anything that didn't come from our REST API (Firestore, Supabase, image encoding, ...).
    case unknown(String)

    /// Wraps an arbitrary error, passing a `WishieError` through unchanged.
    init(_ error: Error) {
        if let wishieError = error as? WishieError {
            self = wishieError
        } else {
            self = .unknown(error.localizedDescription)
        }
    }

    var errorDescription: String? { message }

    /// Non-optional so it can go straight into an alert.
    var message: String {
        switch self {
        case .server(_, let message, _, _): return message
        case .unauthorized(let underlying): return underlying?.message ?? "Unauthorized."
        case .sessionExpired: return "Your session has expired. Please log in again."
        case .invalidResponse: return "Unexpected server response."
        case .transport(let message): return message
        case .unknown(let message): return message
        }
    }

    var statusCode: Int? {
        switch self {
        case .server(let statusCode, _, _, _): return statusCode
        case .unauthorized: return 401
        default: return nil
        }
    }

    var code: String? {
        if case .server(_, _, _, let code) = self { return code }
        return nil
    }

    static func decodeServerError(data: Data, statusCode: Int) -> WishieError {
        struct ServerErrorBody: Decodable {
            let statusCode: Int?
            let message: String
            let error: String?
            let code: String?

            enum CodingKeys: String, CodingKey { case statusCode, message, error, code }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
                error = try container.decodeIfPresent(String.self, forKey: .error)
                code = try container.decodeIfPresent(String.self, forKey: .code)
                if let single = try? container.decode(String.self, forKey: .message) {
                    message = single
                } else if let multiple = try? container.decode([String].self, forKey: .message) {
                    message = multiple.joined(separator: "\n")
                } else {
                    message = "Unexpected error"
                }
            }
        }
        guard let body = try? JSONDecoder().decode(ServerErrorBody.self, from: data) else {
            return .server(statusCode: statusCode, message: "Unexpected error")
        }
        return .server(statusCode: body.statusCode ?? statusCode, message: body.message, error: body.error, code: body.code)
    }
}
