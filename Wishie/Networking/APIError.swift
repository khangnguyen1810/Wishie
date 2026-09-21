import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case server(statusCode: Int, message: String, code: String?)
    indirect case unauthorized(APIError?)
    case sessionExpired
    case invalidResponse
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .server(_, let message, _): return message
        case .unauthorized(let underlying): return underlying?.errorDescription ?? "Unauthorized."
        case .sessionExpired: return "Your session has expired. Please log in again."
        case .invalidResponse: return "Unexpected server response."
        case .transport(let message): return message
        }
    }

    var code: String? {
        if case .server(_, _, let code) = self { return code }
        return nil
    }

    static func decodeServerError(data: Data, statusCode: Int) -> APIError {
        struct ServerErrorBody: Decodable {
            let statusCode: Int?
            let message: String
            let code: String?

            enum CodingKeys: String, CodingKey { case statusCode, message, code }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
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
            return .server(statusCode: statusCode, message: "Unexpected error", code: nil)
        }
        return .server(statusCode: body.statusCode ?? statusCode, message: body.message, code: body.code)
    }
}
