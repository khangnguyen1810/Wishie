import Foundation

struct Endpoint {
    enum Body {
        case json(Data)
        case multipart(fieldName: String, fileName: String, mimeType: String, fileData: Data)
        case none
    }

    let path: String
    let method: String
    let body: Body
    let requiresAuth: Bool

    static func get(_ path: String, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path: path, method: "GET", body: .none, requiresAuth: requiresAuth)
    }

    static func post(_ path: String, json: Data? = nil, requiresAuth: Bool = false) -> Endpoint {
        Endpoint(path: path, method: "POST", body: json.map(Body.json) ?? .none, requiresAuth: requiresAuth)
    }

    static func patch(_ path: String, json: Data, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path: path, method: "PATCH", body: .json(json), requiresAuth: requiresAuth)
    }

    static func postMultipart(_ path: String, fieldName: String, fileName: String, mimeType: String, fileData: Data, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path: path, method: "POST", body: .multipart(fieldName: fieldName, fileName: fileName, mimeType: mimeType, fileData: fileData), requiresAuth: requiresAuth)
    }
}
