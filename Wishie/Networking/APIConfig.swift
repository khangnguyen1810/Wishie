import Foundation

enum APIConfig {
    #if targetEnvironment(simulator)
    static let baseURL = URL(string: "http://localhost:3000")!
    #else
    // wishie-server isn't deployed yet (see API.md — "not deployed yet"). For physical-device
    // testing, replace this with your Mac's LAN IP, found via `ipconfig getifaddr en0`.
    // It changes whenever you reconnect to a different Wi-Fi network.
    static let baseURL = URL(string: "http://192.168.1.100:3000")!
    #endif
}
