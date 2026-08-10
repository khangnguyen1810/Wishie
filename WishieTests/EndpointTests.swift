import Testing
import Foundation
@testable import Wishie

struct EndpointTests {
    @Test func getDefaultsToRequiringAuth() {
        let endpoint = Endpoint.get("/profiles/me")

        #expect(endpoint.method == "GET")
        #expect(endpoint.path == "/profiles/me")
        #expect(endpoint.requiresAuth == true)
        if case .none = endpoint.body {} else { Issue.record("expected .none body") }
    }

    @Test func postDefaultsToNotRequiringAuth() {
        let json = Data("{}".utf8)
        let endpoint = Endpoint.post("/auth/login", json: json)

        #expect(endpoint.method == "POST")
        #expect(endpoint.requiresAuth == false)
        if case .json(let data) = endpoint.body {
            #expect(data == json)
        } else {
            Issue.record("expected .json body")
        }
    }

    @Test func patchDefaultsToRequiringAuth() {
        let json = Data("{}".utf8)
        let endpoint = Endpoint.patch("/profiles/me", json: json)

        #expect(endpoint.method == "PATCH")
        #expect(endpoint.requiresAuth == true)
    }

    @Test func postMultipartCarriesFileFields() {
        let fileData = Data([0x01, 0x02])
        let endpoint = Endpoint.postMultipart("/profiles/me/avatar", fieldName: "file", fileName: "u1.jpg", mimeType: "image/jpeg", fileData: fileData)

        #expect(endpoint.method == "POST")
        #expect(endpoint.requiresAuth == true)
        if case .multipart(let fieldName, let fileName, let mimeType, let data) = endpoint.body {
            #expect(fieldName == "file")
            #expect(fileName == "u1.jpg")
            #expect(mimeType == "image/jpeg")
            #expect(data == fileData)
        } else {
            Issue.record("expected .multipart body")
        }
    }
}
