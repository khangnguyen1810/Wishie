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
                        .padding(.horizontal, 15)
                        .padding(.top, 15)
                    listContent()
                }
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
            if viewModel.wishlistInfo.isOwner() {
                Button {
                    viewModel.showAddItemOptionSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 50)
                        .background(Color(hex: viewModel.wishlistInfo.theme.secondary))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .padding(.bottom, 24)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
        .sheet(isPresented: $viewModel.showAddItemOptionSheet) {
            AddItemOptionSheet(
                onPasteLink: {
                    viewModel.showAddItemOptionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showAddItemPasteLinkSheet = true
                    }
                },
                onManual: {
                    viewModel.showAddItemOptionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showAddItemManualSheet = true
                    }
                }
            )
            .presentationDetents([.height(280)])
        }
        .sheet(
            isPresented: $viewModel.showAddItemManualSheet,
            onDismiss: {
                viewModel.newItemName = ""
                viewModel.newItemDescription = ""
                viewModel.newItemImage = nil
                viewModel.newItemLink = ""
                viewModel.newItemRemoteImageUrl = nil
                viewModel.metadataFetchError = nil
            }
        ) {
            AddItemManualDetailSheet(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "")
                .presentationDetents([.large])
        }
        .sheet(
            isPresented: $viewModel.showAddItemPasteLinkSheet,
            onDismiss: {
                viewModel.newItemName = ""
                viewModel.newItemDescription = ""
                viewModel.newItemImage = nil
                viewModel.newItemLink = ""
                viewModel.newItemRemoteImageUrl = nil
                viewModel.metadataFetchError = nil
            }
        ) {
            AddItemPasteLinkDetailSheet(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "")
                .presentationDetents([.large])
        }
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
        .showDialogIfNeeded(
            $viewModel.showDeleteConfirmation,
            title: "Delete item?",
            message: "This action cannot be undone.",
            showCancel: true,
            onOk: {
                Task {
                    let wId = viewModel.wishlistInfo.id
                    await viewModel.deleteWishlistItem(wishlistId: wId)
                }
            },
            onCancel: {
                viewModel.showBottomSheet = true
            }
        )
        .showDialogIfNeeded(
            $viewModel.showReserveConfirmation,
            title: "Reserve this gift?",
            message: "Do you want to select this gift?",
            showCancel: true,
            onOk: {
                Task {
                    let wId = viewModel.wishlistInfo.id
                    await viewModel.pickItem(wishlistId: wId)
                }
            },
            onCancel: {
                viewModel.showBottomSheet = true
            }
        )
        .task {
            let id = wishlistId ?? wishlist?.id
            guard let id else { return }
            viewModel.startObservingWishlist(wishlistId: id, showInitialLoading: wishlist == nil)
        }
        .onAppear(perform: {
            guard let wishlist else { return }
            viewModel.setInitialWishlist(wishlist)
        })
        .navigationBarBackButtonHidden()
    }
    @ViewBuilder
    func headerContent() -> some View {
        let pickedCount = viewModel.wishlistInfo.items.filter(\.isPicked).count
        let totalCount = viewModel.wishlistInfo.items.count
        let progress = totalCount > 0 ? Double(pickedCount) / Double(totalCount) : 0.0
        VStack(spacing: 15) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color(hex: viewModel.wishlistInfo.theme.secondary))
                    Text("\(totalCount) items")
                        .font(.wishies(.regular, 16))
                        .foregroundStyle(.black)
                }
                
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
            HStack(spacing: 0) {
                HStack(spacing: 15) {
                    GiftProgressView(progress: progress)
                        .frame(width: 32, height: 32)
                    Text("\(pickedCount)/\(totalCount) gifts selected")
                        .font(.wishies(.regular, 14))
                        .foregroundStyle(.darkGrey)
                }
                Spacer()
                HStack(spacing: -8) {
                    ForEach(Array(viewModel.memberUsers.prefix(3)), id: \.self) { user in
                        ZStack {
                            Circle()
                                .fill(Color(hex: viewModel.wishlistInfo.theme.secondary))
                                .frame(width: 28, height: 28)
                            Text(String(user.firstName.prefix(1).uppercased()))
                                .font(.wishies(.bold, 14))
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    if viewModel.memberUsers.count > 3 {
                        ZStack {
                            Circle()
                                .fill(Color(hex: viewModel.wishlistInfo.theme.secondary))
                                .frame(width: 28, height: 28)
                            Text("+\(viewModel.memberUsers.count - 3)")
                                .font(.wishies(.bold, 12))
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                }
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
        ScrollView {
            LazyVStack(spacing: 12) {
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

                        if item.isMostDesired {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .frame(width: 16, height: 16)
                        }

                        if item.isPicked {
                            Spacer()
                            Image("user")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                    )
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
            .padding(.horizontal, 15)
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
                    if let price = viewModel.itemSelected.price, !price.isEmpty {
                        Text(price)
                            .font(.wishies(.bold, 15))
                            .foregroundStyle(.darkGrey)
                    }
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
                                    isEditing = false
                                    viewModel.showBottomSheet = false
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
                        if !viewModel.itemSelected.isMostDesired && !isEditing {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(hex: viewModel.wishlistInfo.theme.secondary))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 45)
                                HStack {
                                    Image(systemName: "star.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25)
                                        .padding(.leading, 20)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Mark as Most Desired")
                                    .font(.wishies(.bold, 15))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .onTapGesture {
                                Task {
                                    await viewModel.setMostDesired(wishlistId: wishlist?.id ?? "")
                                    viewModel.showBottomSheet = false
                                }
                            }
                        }
                        if !isEditing {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(viewModel.itemSelected.isPicked ? .lightGrey : .wishiePink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 45)
                                HStack {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25)
                                        .padding(.leading, 20)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Delete")
                                    .font(.wishies(.bold, 15))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .disabled(viewModel.itemSelected.isPicked)
                            .onTapGesture {
                                if !viewModel.itemSelected.isPicked {
                                    viewModel.showBottomSheet = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        viewModel.showDeleteConfirmation = true
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
            if !viewModel.itemSelected.isPicked {
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showReserveConfirmation = true
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
