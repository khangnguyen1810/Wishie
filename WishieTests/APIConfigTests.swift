import Testing
@testable import Wishie

struct APIConfigTests {
    @Test func baseURLIsAWellFormedLocalHTTPURLOnPort3000() {
        #expect(APIConfig.baseURL.scheme == "http")
        #expect(APIConfig.baseURL.port == 3000)
    }
}
