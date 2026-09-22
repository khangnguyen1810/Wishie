//
//  WishListInformationView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//


import SwiftUI

struct WishListInformationView: View {
    /// Everything shown here comes from the scanned join code's preview response — the screen
    /// deliberately does not re-fetch, because the caller is not a member yet and the full
    /// wishlist endpoint would reject them.
    var preview: WishlistJoinPreview
    @Binding var path: NavigationPath
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WishListInformationViewModel = WishListInformationViewModel()
    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 50, height: 50)
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
                Text("Wishlist's information")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            ScrollView {
                VStack(spacing: 30) {
                    Text("Wishlist name")
                        .font(.wishies(.regular, 16))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(preview.name)
                        .multilineTextAlignment(.leading)
                        .font(.wishies(.bold, 17))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal,15)
                        .background {
                            RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                                .frame(height: 56)
                        }
                }
                .padding(.vertical,30)
                VStack (spacing: 15) {
                    Text("Description")
                        .font(.wishies(.regular, 16))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(preview.description)
                        .multilineTextAlignment(.leading)
                        .disabled(true)
                        .font(.wishies(.regular, 17))
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: 100, alignment: .topLeading)
                        .lineLimit(2...4)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.lightYellow)
                        )
                }
                .padding(.bottom,20)
                // `API.md` doesn't list an owner on the join-preview response, so this section is
                // dropped entirely when it's absent rather than rendering a labelled blank.
                if let ownerName = preview.ownerName, !ownerName.isEmpty {
                    VStack(spacing: 30) {
                        Text("Created by")
                            .font(.wishies(.regular, 16))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack (spacing: 15) {
                            Circle()
                                .fill(.lightYellow1)
                                .frame(width: 50, height: 50)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                }
                            Text(ownerName)
                                .multilineTextAlignment(.leading)
                                .font(.wishies(.regular, 16))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal,15)
                        .background {
                            RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                                .frame(height: 80)
                        }
                    }
                    .padding(.bottom, 30)
                }
                VStack(spacing: 30) {
                    Text("Due date")
                        .font(.wishies(.regular, 16))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack (spacing: 15) {
                        Image("date_wishlist")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(preview.dueDate.toShortDateString())
                            .multilineTextAlignment(.leading)
                            .font(.wishies(.regular, 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal,15)
                    .background {
                        RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                            .frame(height: 56)
                    }
                }
                .padding(.bottom, 60)

                // The join preview carries only `itemCount` — member and remaining-item counts
                // aren't known until the caller is actually a member, so they aren't shown here.
                itemWishlistInfo(
                    value: "\(preview.itemCount)",
                    title: "Items"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                }
            }
            WishieButton(
                title: "Join",
                enabled: !viewModel.isLoading,
                action: {
                    Task { await viewModel.join(code: preview.code, wishlistId: preview.id) }
                }
            )
        }
        .showFullScreenDialog($viewModel.isLoading)
        .showDialogIfNeeded($viewModel.joinFailed, title: "Can not join", message: viewModel.joinErrorMessage)
        .onChange(of: viewModel.joinedWishlistId) { _, wishlistId in
            guard let wishlistId else { return }
            path.append(
                Route.wishListDetailScreen(
                    wishlistId: wishlistId,
                    isFromInfo: true
                )
            )
        }
    }
    @ViewBuilder
    func itemWishlistInfo(value: String, title: String) -> some View {
        VStack {
            Text(value)
                .font(.wishies(.regular, 18))
                .foregroundStyle(.black)
            Text(title)
                .font(.wishies(.regular, 14))
                .foregroundStyle(.darkGrey)
        }
    }
}

#Preview {
    WishListInformationView(
        preview: WishlistJoinPreview(
            code: "ABC123",
            id: "136D375B-7015-4C9A-97BE-830C5C46F24A",
            name: "Birthday wishlist",
            description: "A few things I'd love this year.",
            dueDate: Date(),
            themeColor: nil,
            itemCount: 12,
            ownerName: "Ann Nguyen"
        ),
        path: .constant(NavigationPath())
    )
}
