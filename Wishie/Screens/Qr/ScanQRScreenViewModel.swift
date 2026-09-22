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
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isScanning: Bool = false
    @Published var errorTitle: String = ""
    @Published var preview: WishlistJoinPreview?
    /// Set only when the user dismisses the error dialog. Restarting the capture session while
    /// the dialog is still up put the same bad QR straight back through `handleResult`, looping
    /// error → restart → error and pinning the dialog on screen.
    @Published var shouldRestartScanning: Bool = false
    private let wishlistService: WishlistServiceProtocol

    init(wishlistService: WishlistServiceProtocol = WishlistService()) {
        self.wishlistService = wishlistService
    }

    func handleResult(_ value: String) async {
        guard let url = URL(string: value),
              let code = WishieLinks.joinCode(from: url) else {
            showInvalidURLError()
            return
        }
        preview = await loadPreview(code: code)
    }

    /// Called once the view has consumed `preview` to navigate. Without this, re-scanning the
    /// same code produces an identical value, `onChange` never fires, and the screen silently
    /// does nothing.
    func didNavigateToPreview() {
        preview = nil
    }

    /// The capture session stops on every decoded frame, so it has to be told to resume once the
    /// user has acknowledged the error and is still on this screen.
    func didDismissError() {
        shouldRestartScanning = true
    }

    private func showInvalidURLError() {
        showError(title: "Invalid URL", message: "Please scan a valid Wishie wishlist QR.")
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

    /// Returns `nil` when the lookup fails, which also clears `preview` so the screen never
    /// navigates to an info screen built from placeholder data.
    private func loadPreview(code: String) async -> WishlistJoinPreview? {
        isScanning = true
        defer { isScanning = false }

        switch await wishlistService.getWishlistInfoByCode(by: code) {
        case .success(let response):
            return WishlistJoinPreview(code: code, response: response)
        case .failure(let failure):
            if case .server(404, _, _)? = failure as? APIError {
                showError(
                    title: "Invite no longer valid",
                    message: "This QR code has expired or been revoked. Ask for a new one."
                )
            } else {
                showError(title: "Can't get wishlist info", message: failure.localizedDescription)
            }
            return nil
        }
    }
}
