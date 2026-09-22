//
//  QRScannerViewController.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/1/26.
//

import UIKit
import AVFoundation

final class QRScannerViewController: UIViewController {

    var onResult: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    /// `startRunning()` blocks until the session is configured, so it must never run on main.
    private let sessionQueue = DispatchQueue(label: "com.wishie.qrscanner.session")
    /// `stopRunning()` is async on `sessionQueue`, so more frames can still land before it takes
    /// effect. Without this, one scan could fire `onResult` several times.
    private var isHandlingResult = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }

    private func setupScanner() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput)
        else {
            return
        }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
    }

    /// Starting here rather than in `setupScanner()` is what makes the scanner survive a round
    /// trip to the preview screen: `viewWillDisappear` stops the session, and previously nothing
    /// ever started it again, so coming back left a frozen camera with no way to recover.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [captureSession] in
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    func restartScanning() {
        startSession()
    }

    private func startSession() {
        isHandlingResult = false
        sessionQueue.async { [captureSession] in
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !isHandlingResult,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue
        else { return }

        isHandlingResult = true

        sessionQueue.async { [captureSession] in
            captureSession.stopRunning()
        }
        onResult?(value)
    }
    
}
