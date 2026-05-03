//
//  ScanQRScreenViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//

import Foundation

class ScanQRScreenViewModel: ObservableObject {
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isScanning: Bool = false
    @Published var errorTitle: String = ""
    @Published var result: WishlistQRPayload = WishlistQRPayload(wishListId: "")
    func handleResult(_ value: String) {
       
        guard let url = URL(string: value),
              url.scheme == "wishie",
              url.host == "wishlist"
        else {
           showInvalidURLError()
            return
        }
        if let payload = decodePayload(from: url) {
            result = payload
            
            return
        }
        showInvalidURLError()
    }
    private func showInvalidURLError() {
        showError = true
        errorTitle = "Invalid URL"
        errorMessage = "Please scan a valid Wishie wishlist QR."
    }
    private func decodePayload(from url: URL) -> WishlistQRPayload? {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let dataString = components.queryItems?
                .first(where: { $0.name == "data" })?
                .value,
            let data = Data(base64Encoded: dataString),
            let payload = try? JSONDecoder().decode(WishlistQRPayload.self, from: data)
        else { return nil }
        
        return payload
    }
}
