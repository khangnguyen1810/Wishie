//
//  ScanQRScreenViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//

import Foundation
import UIKit
import Vision

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
            
            DispatchQueue.main.async {
                self.handleResult(qrValue)
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
        DispatchQueue.main.async {
            self.showError = true
            self.errorTitle = title
            self.errorMessage = message
        }
    }
}
