//
//  WishlistQRCodeView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 21/1/26.
//

import SwiftUI

struct WishlistQRCodeView: View {
    
    let wishlistId: String
    @StateObject private var viewModel = WishlistQRCodeViewModel()
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
                Text("Share Wishlist's QR")
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
                        guard viewModel.qrImage != nil else { return }
                        showShareSheet = true
                    }
                    .opacity(viewModel.qrImage == nil ? 0.4 : 1)
                    .padding(.trailing, 10)
            }
        } content: {
            GeometryReader { geo in
                VStack(spacing: 16) {
                    Text("Scan to open wishlist")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.darkGrey)
                    
                    if let qrImage = viewModel.qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                    } else {
                        // Keeps the layout from jumping once the invite code arrives.
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.lightYellow)
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
            if let qrImage = viewModel.qrImage {
                ShareSheet(items: [qrImage])
            }
        }
        .showFullScreenDialog($viewModel.isLoading)
        .showDialogIfNeeded(
            $viewModel.loadFailed,
            title: "Can't share this wishlist",
            message: viewModel.errorMessage
        )
        .task {
            await viewModel.loadQRCode(wishlistId: wishlistId)
        }
    }
}
