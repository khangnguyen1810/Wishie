//
//  WishListInformationView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//


import SwiftUI

struct WishListInformationView: View {
    var wishlistId: String
    @Binding var path: NavigationPath
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WishListInformationViewModel = WishListInformationViewModel()
    @State private var showLoading = false
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
                    Text(viewModel.wishlistInfo.name)
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
                    Text(viewModel.wishlistInfo.description)
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
                        Text(viewModel.ownerInfo.getFullName())
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
                VStack(spacing: 30) {
                    Text("Due date")
                        .font(.wishies(.regular, 16))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack (spacing: 15) {
                        Image("date_wishlist")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(viewModel.wishlistInfo.dueDate.toShortDateString())
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
                
                HStack (spacing: 15) {
                    itemWishlistInfo(
                        value: "\(viewModel.wishlistInfo.items.count)",
                        title: "Items"
                    )
                    Spacer()
                    Rectangle()
                        .fill(.darkGrey)
                        .frame(width: 1)
                    Spacer()
                    itemWishlistInfo(
                        value: "\(viewModel.wishlistInfo.members.count)",
                        title: "Members"
                    )
                    Spacer()
                    Rectangle()
                        .fill(.darkGrey)
                        .frame(width: 1)
                    Spacer()
                    itemWishlistInfo(
                        value: "\(viewModel.wishlistInfo.getItemsRemaining())",
                        title: "Remaining"
                    )
                }
                .padding(.horizontal,25)
                .background {
                    RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                        .frame(height: 76)
                }
            }
            WishieButton(
                title: "Next",
                enabled: true,
                action: {
                    path
                        .append(
                            Route
                                .wishListDetailScreen(
                                    wishlistId: wishlistId,
                                    isFromInfo: true
                                )
                        )
                }
            )
            
        }
        .showFullScreenDialog($viewModel.isLoading)
//        .showDialogIfNeeded($viewModel.joinFailed, title: "Can not join", message: viewModel.joinErrorMessage)
        .task {
            await viewModel.getWishlistInfo(wishListId: wishlistId)
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
        wishlistId: "136D375B-7015-4C9A-97BE-830C5C46F24A",
        path: .constant(NavigationPath())
    )
}
