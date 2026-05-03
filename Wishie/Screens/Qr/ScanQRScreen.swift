//
//  ScanQRScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/1/26.
//


struct ScanQRScreen: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            QRScannerView { value in
                handleResult(value)
            }

            VStack {
                Text("Quét QR code")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 40)

                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    private func handleResult(_ value: String) {
        print("📦 QR value:", value)

        // Ví dụ parse wishlist id
        if let id = value.split(separator: "/").last {
            dismiss()
            // navigate sang wishlist detail
            // path.append(Route.wishlistDetail(id: String(id)))
        }
    }
}