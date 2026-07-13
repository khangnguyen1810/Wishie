//
//  ArchivedWishlistsView.swift
//  Wishie
//

import SwiftUI

struct ArchivedWishlistsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ArchivedWishlistsViewModel()
    @State private var selectedWishlistId: String?
    @State private var showDeleteConfirm = false

    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image("back_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17)
                    }
                    .onTapGesture { dismiss() }
                    .padding(.trailing, 10)
            } center: {
                Text("Archived wishlists")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            if viewModel.archivedWishlists.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                        Image("gift_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                    }
                    Text("No archived wishlists yet")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(Color.black)
                        .multilineTextAlignment(.center)
                    Text("Wishlists you archive from Home will show up here.")
                        .font(.wishies(.regular, 14))
                        .foregroundStyle(.darkGrey)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.archivedWishlists, id: \.0.id) { wishlist in
                            HomeItemViewCell(item: wishlist)
                                .padding(.vertical, 14)
                                .contextMenu {
                                    Button {
                                        Task { await viewModel.unarchiveWishlist(wishlistId: wishlist.0.id) }
                                    } label: {
                                        Label("Unarchive", systemImage: "arrow.uturn.backward")
                                    }
                                    Button(role: .destructive) {
                                        selectedWishlistId = wishlist.0.id
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.loadArchivedWishlists()
                }
            }
        }
        .showFullScreenDialog($viewModel.isLoading)
        .showDialogIfNeeded(
            $showDeleteConfirm,
            title: "Are you sure to delete it?",
            message: "When you delete this wishlist, you can't recover it again.",
            onOk: {
                Task {
                    guard let id = selectedWishlistId else { return }
                    await viewModel.deleteWishlist(wishlistId: id)
                }
                showDeleteConfirm = false
            },
            onCancel: {
                showDeleteConfirm = false
            }
        )
        .task {
            await viewModel.loadArchivedWishlists()
        }
    }
}

#Preview {
    ArchivedWishlistsView()
}
