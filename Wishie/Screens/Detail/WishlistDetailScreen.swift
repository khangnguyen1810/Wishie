//
//  WishlistDetailScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 18/3/26.
//

import SwiftUI
import DotLottie
import SDWebImageSwiftUI

struct WishlistDetailScreen: View {
    @State private var offsetY: CGFloat = 0
    @State private var channelExpnand: Bool = true
    @State private var appExpnand: Bool = true
    @Environment(\.dismiss) private var dismiss
    @State private var sheetHeight: CGFloat = .zero
    @State private var isSharing: Bool = false
    @State private var isEditing: Bool = false
    @State private var showLinkNotValidOrNotExist: Bool = false
    @StateObject private var viewModel: WishlistDetailViewController = WishlistDetailViewController()
    @Binding var navigationPath: NavigationPath
    var wishlist: WishlistModel?
    var owner: UserModel?
    var qrImage: UIImage? {
        
        let payload = WishlistQRPayload(
            wishListId: viewModel.wishlistInfo.id
        )
        
        guard
            let data = try? JSONEncoder().encode(payload)
        else { return nil }
        
        let base64 = data.base64EncodedString()
        let link = "wishie://wishlist?data=\(base64)"
        
        return QRCodeGenerator.generate(from: link)
    }
    var wishlistId: String?
    var isFromInfo: Bool = false
       
    var body: some View {
        ZStack(alignment: .bottom) {
            StickyHeaderView(
                isSharing: $isSharing,
                headerBgColor: viewModel.wishlistInfo.theme.primary,
                buttonColor: viewModel.wishlistInfo.theme.secondary,
                titlePage: "Wishlist detail",
                wishlistTitle: viewModel.wishlistInfo.name,
                owner: owner?.getFullName()
            ) {
                if isFromInfo {
                    navigationPath.removeLast(navigationPath.count)
                } else {
                    dismiss()
                }
            } content: {
                VStack (spacing: 15) {
                    headerContent()
                    listContent()
                }
                .padding(.horizontal, 15)
                .padding(.top,15)
            }
            if viewModel.wishlistInfo.isUserJoined() == false {
                    WishieButton(
                        title: "Join wishlist",
                        enabled: true,
                        height: 50,
                        horizontalPadding: 15
                    ) {
                        Task {
                            await viewModel
                                .joinWishlist(wishListId: wishlistId ?? "")
                                           }
                    }
                }
        }
        .sheet(isPresented: $viewModel.showBottomSheet) {
            bottomSheet()
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isSharing, content: {
            if let qrImage {
                ShareSheet(items: [qrImage])
            }
        })
        .showFullScreenDialog($viewModel.isShowLoading)
        .showDialogIfNeeded(
            $viewModel.isShowError,
            title: "General Error",
            message: viewModel.errorMessage
        )
        .showDialogIfNeeded(
            $showLinkNotValidOrNotExist,
            title: "Not have a link",
            message: "This item doesn't have a link yet."
        )
        .task {
            guard let wishlistId else { return }
            await viewModel.getWishlistInfo(wishListId: wishlistId)
        }
        .onAppear(perform: {
            guard let wishlist else { return }
            viewModel.setInitialWishlist(wishlist)
        })
        .navigationBarBackButtonHidden()
    }
    @ViewBuilder
    func headerContent() -> some View {
        VStack(spacing: 15) {
            HStack {
                let itemCount = viewModel.wishlistInfo.items.count
                Text("\(itemCount) Items")
                    .font(.wishies(.regular, 16))
                    .foregroundStyle(.black)
                
                Spacer()
                Image("date_wishlist")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.darkGrey)
                Text(viewModel.wishlistInfo.dueDate.toShortDateString())
                    .font(Font.wishies(.regular, 16))
                    .foregroundStyle(.darkGrey)
            }
            Text(viewModel.wishlistInfo.description)
                .font(.wishies(.regular, 15))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.darkGrey)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    func listContent() -> some View {
        VStack() {
            ForEach(viewModel.wishlistInfo.items, id: \.self) { item in
                HStack {
                    WebImage(url: URL(string: item.image ?? ""), content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }, placeholder: {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                Color(hex: viewModel.wishlistInfo.theme.secondary)
                            )
                            .frame(
                                width: UIScreen.main.bounds.width/4,
                                height:  UIScreen.main.bounds.width/4
                            )
                            .overlay {
                                DotLottieAnimation(fileName: "giftloading", config: AnimationConfig(autoplay: true, loop: true)).view()
                                    .frame(width: 40)
                            }
                    })
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(10)
                    
                    Text(item.name)
                        .font(.wishies(.regular, 15))
                        .foregroundStyle(.black)
                    
                    if (item.isPicked) {
                        Spacer()
                        Image("user")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .overlay {
                    if item.isPicked {
                        Color(hex: viewModel.wishlistInfo.theme.primary)
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        
                    }
                }
                .onTapGesture {
                    viewModel.itemSelected = item
                    viewModel.showBottomSheet = true
                }
            }
        }
    }
    @ViewBuilder
    func bottomSheet() -> some View {
        ZStack(alignment: .topLeading) {
            Color(hex: viewModel.wishlistInfo.theme.primary).ignoresSafeArea()
            VStack(spacing: 15) {
                HStack {
                    ZStack {
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            WebImage(url: URL(string: viewModel.itemSelected.image ?? ""), content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            }, placeholder: {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        Color(hex: viewModel.wishlistInfo.theme.secondary)
                                    )
                                    .frame(
                                        width: UIScreen.main.bounds.width/4,
                                        height:  UIScreen.main.bounds.width/4
                                    )
                                    .overlay {
                                        DotLottieAnimation(
                                            fileName: "giftloading",
                                            config: AnimationConfig(autoplay: true, loop: true)
                                        )
                                        .view()
                                        .frame(width: 40)
                                    }
                            })
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if isEditing {
                            ImagePickerBox(
                                height: 100,
                                selectedImage: $viewModel.selectedImage) {
                                    Image("edit_icon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(
                                            Color(
                                                hex: viewModel.wishlistInfo.theme.secondary
                                            )
                                        )
                                        .frame(width: 16, height: 16)
                                        .padding(6)
                                        .background(Color(hex: viewModel.wishlistInfo.theme.primary))
                                        .clipShape(Circle())
                                        .padding(4)
                                }
                        }
                    }
                    VStack {
                        if isEditing {
                            TextField("Item name", text: $viewModel.editedName)
                                .textFieldStyle(.plain)
                                .font(.wishies(.bold, 15))
                            
                            TextField("Description", text: $viewModel.editedDescription)
                                .textFieldStyle(.plain)
                                .font(.wishies(.regular, 15))
                        } else {
                            Text(viewModel.itemSelected.name)
                                .font(.wishies(.bold, 15))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(viewModel.itemSelected.description)
                                .font(.wishies(.regular, 15))
                                .foregroundStyle(.darkGrey)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("Price")
                        .font(.wishies(.bold, 15))
                        .foregroundStyle(.black)
                    Spacer()
                    Text("100.00 - 200.000 VND")
                        .font(.wishies(.bold, 15))
                        .foregroundStyle(.darkGrey)
                }
                Spacer()
                if wishlist?.isOwner() == true {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    Color(hex: viewModel.wishlistInfo.theme.secondary)
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 45)
                            HStack {
                                Image(isEditing ? "save_icon" : "create_new_icon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25)
                                    .padding(.leading, 20)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(isEditing ? "Save" : "Edit this item")
                                .font(.wishies(.bold, 15))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .onTapGesture {
                            if isEditing {
                                //save item
                                Task {
                                    await viewModel
                                        .editWishlistItem(
                                            wishListId: wishlist?.id ?? ""
                                        )
                                    viewModel.itemSelected.name = viewModel.editedName
                                    viewModel.itemSelected.description = viewModel.editedDescription
                                    isEditing = false
                                }
                            } else {
                                isEditing = true
                                viewModel.editedName = viewModel.itemSelected.name
                                viewModel.editedDescription = viewModel.itemSelected.description
                            }
                        }
                        if isEditing {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        .wishiePink
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 45)
                                HStack {
                                    Image("back_icon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25)
                                        .padding(.leading, 20)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Cancel")
                                    .font(.wishies(.bold, 15))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .onTapGesture {
                                isEditing = false
                            }
                            
                            .onTapGesture {
                                Task {
                                    if (!viewModel.itemSelected.isPicked) {
                                        viewModel.showBottomSheet = false
                                        let wishlistId = viewModel.wishlistInfo.id
                                        await viewModel.pickItem(wishlistId: wishlistId)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                        linkButton()
                        reserveButton()
                    }
                }
            }
            .padding()
        }
    }
    @ViewBuilder
    func reserveButton() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    viewModel.itemSelected.isPicked ? .lightGrey : .wishiePink
                )
                .frame(maxWidth: .infinity)
                .frame(height: 45)
            HStack {
                Image("reserve_item")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25)
                    .padding(.leading, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("Reserve")
                .font(.wishies(.bold, 15))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onTapGesture {
            Task {
                if (!viewModel.itemSelected.isPicked) {
                    viewModel.showBottomSheet = false
                    let wishlistId = viewModel.wishlistInfo.id
                    await viewModel.pickItem(wishlistId: wishlistId)
                }
            }
        }
    }
    @ViewBuilder
    func linkButton() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    Color(hex: viewModel.wishlistInfo.theme.secondary)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 45)
            HStack {
                Image("link_item")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25)
                    .padding(.leading, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("Link")
                .font(.wishies(.bold, 15))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onTapGesture {
            viewModel.openProductLink()
        }
    }
}
