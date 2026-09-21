//
//  ScanQRScreenViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//

import Foundation
import UIKit
import Vision

@MainActor
class ScanQRScreenViewModel: ObservableObject {
    static let joinHost = "wishie-web.vercel.app"

    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isScanning: Bool = false
    @Published var errorTitle: String = ""
    @Published var result: String = ""
    @Published var shouldRestartScanning: Bool = false
    private let wishlistService: WishlistServiceProtocol

    init(wishlistService: WishlistServiceProtocol = WishlistService()) {
        self.wishlistService = wishlistService
    }
    func handleResult(_ value: String) async {

        guard let url = URL(string: value),
              url.scheme == "https",
              url.host == Self.joinHost else {
            showInvalidURLError()
            return
        }
        if let payload = decodePayload(from: url) {
            result = await getWishlistInfoByCode(by: payload.wishListId)
            return
        }
        showInvalidURLError()
    }
    private func showInvalidURLError() {
        showError = true
        errorTitle = "Invalid URL"
        errorMessage = "Please scan a valid Wishie wishlist QR."
        shouldRestartScanning = true
    }
    private func decodePayload(from url: URL) -> WishlistQRPayload? {
        let component = url.pathComponents
        guard let joinIndex = component.firstIndex(of: "join"),
              component.count > joinIndex + 1 else {
            return nil
        }
        let code = component[joinIndex + 1]

        return code.isEmpty ? nil : WishlistQRPayload(wishListId: code)
    }

    func detectQRCode(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            showError(title: "Invalid Image", message: "Unable to process the selected image.")
            return
        }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                self.showError(title: "Detection Failed", message: error.localizedDescription)
                return
            }

            guard let results = request.results as? [VNBarcodeObservation],
                  let firstBarcode = results.first,
                  let qrValue = firstBarcode.payloadStringValue else {
                self.showError(title: "No QR Code Found", message: "No valid QR code was detected in the image.")
                return
            }

            Task {
                await self.handleResult(qrValue)
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            showError(title: "Processing Error", message: error.localizedDescription)
        }
    }

    private func showError(title: String, message: String) {
        showError = true
        errorTitle = title
        errorMessage = message
    }

    /// Only the wishlist id is needed to navigate to the detail screen, which re-fetches full details itself.
    private func getWishlistInfoByCode(by code: String) async -> String {
        isScanning = true
        defer { isScanning = false }
        do {
            let result = try await wishlistService.getWishlistInfoByCode(by: code)
            switch result {
            case .success(let response):
                return response.id
            case .failure(let failure):
                showError(title: "Can't get wishlist info", message: failure.localizedDescription)
                shouldRestartScanning = true
                return ""
            }
        } catch {
            showError(title: "Can't get wishlist info", message: error.localizedDescription)
            shouldRestartScanning = true
            return ""
        }
    }
}
