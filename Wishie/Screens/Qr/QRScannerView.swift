//
//  QRScannerView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/1/26.
//


import SwiftUI

struct QRScannerView: UIViewControllerRepresentable {

    var onResult: (String) -> Void
    @Binding var restartScanning: Bool

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onResult = onResult
        return vc
    }

    func updateUIViewController(
        _ uiViewController: QRScannerViewController,
        context: Context
    ) {
        guard restartScanning else { return }
        uiViewController.restartScanning()
        DispatchQueue.main.async {
            restartScanning = false
        }
    }
}
