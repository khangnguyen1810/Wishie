import Testing
@testable import Wishie

struct APIConfigTests {
    @Test func baseURLIsAWellFormedHTTPSURL() {
        #expect(APIConfig.baseURL.scheme == "https")
        #expect(APIConfig.baseURL.host?.isEmpty == false)
    }
}
