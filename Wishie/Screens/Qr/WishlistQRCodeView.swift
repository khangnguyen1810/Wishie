//
//  WishlistQRCodeView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 21/1/26.
//

import SwiftUI

struct WishlistQRCodeView: View {
    
    let wishlistId: String
    var qrImage: UIImage? {
        let payload = WishlistQRPayload(
            wishListId: wishlistId
        )

        guard
            let data = try? JSONEncoder().encode(payload)
        else { return nil }

        let base64 = data.base64EncodedString()
        let link = "wishie://wishlist?data=\(base64)"

        return QRCodeGenerator.generate(from: link)
    }
    @State private var showShareSheet = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 40, height: 40)
                    .overlay(content: {
                        Image("back_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    })
                    .onTapGesture {
                        dismiss()
                    }
                    .padding(.trailing, 10)
            } center: {
                Text("Create new wishlist")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            } trailing: {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 50, height: 50)
                    .overlay(content: {
                        Image("share")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    })
                    .onTapGesture {
                        showShareSheet = true
                    }
                    .padding(.trailing, 10)
            }
        } content: {
            GeometryReader { geo in
                VStack(spacing: 16) {
                    Text("Scan to open wishlist")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.darkGrey)
                    
                    if let qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                    }
                    
                    Text("Share this QR code with your friends")
                        .font(.wishies(.regular, 17))
                        .foregroundColor(.darkGrey)
                }
                .frame(
                    width: geo.size.width,
                    height: geo.size.height * 0.7,
                    alignment: .center
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let qrImage {
                ShareSheet(items: [qrImage])
            }
        }
    }
}
