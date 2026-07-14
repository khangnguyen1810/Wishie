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
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.4))
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
            WishItemDetailView(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "", isEdit: false)
                .environmentObject(viewModel)
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
        .sheet(
            isPresented: $viewModel.showEditItemSheet,
            onDismiss: {
                viewModel.newItemName = ""
                viewModel.newItemDescription = ""
                viewModel.newItemImage = nil
                viewModel.newItemLink = ""
                viewModel.newItemRemoteImageUrl = nil
                viewModel.newItemPrice = ""
                viewModel.metadataFetchError = nil
            }
        ) {
            WishItemDetailView(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "", isEdit: true, wishItem: viewModel.itemSelected)
                .environmentObject(viewModel)
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
                            .fill(
                                item.isPicked
                                    ? Color(hex: viewModel.wishlistInfo.theme.primary).lightened(by: 0.6)
                                    : Color.white
                            )
                    )
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
            Color(hex: viewModel.wishlistInfo.theme.primary).lightened(by: 0.45).ignoresSafeArea()
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
                    VStack {
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
                        HStack {
                            editButton()
                            markDesireButton()
                        }
                        linkButton()
                        deleteButton()
                    }
                } else {
                    VStack {
                        linkButton()
                        reserveButton()
                    }
                }
            }
            .padding()
            .padding(.top,30)
        }
    }
    @ViewBuilder
    func reserveButton() -> some View {
        bottomSheetButton(
            title: "Reserve",
            fill: viewModel.itemSelected.isPicked ? .lightGrey : .wishiePink
        ) {
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
        bottomSheetButton(
            title: "Link",
            fill: Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.4),
            action:  {
                viewModel.openProductLink()
            }
        )
    }
    
    @ViewBuilder
    func deleteButton() -> some View {
        bottomSheetButton(
            title: "Delete",
            fill: viewModel.itemSelected.isPicked ? .lightGrey : .wishiePink
        ) {
            if !viewModel.itemSelected.isPicked {
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showDeleteConfirmation = true
                }
            }
        }
        .disabled(viewModel.itemSelected.isPicked)
    }
    
    @ViewBuilder
    func markDesireButton() -> some View {
        bottomSheetButton(
            title: viewModel.itemSelected.isMostDesired ? "Remove most desired" : "Mark as Most Desired",
            fill: Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.4)
        ) {
            Task {
                await viewModel.setDesired(
                    wishlistId: wishlist?.id ?? "",
                    isDesired: viewModel.itemSelected.isMostDesired ? false : true
                )
                viewModel.showBottomSheet = false
            }
        }
    }
    
    @ViewBuilder
    func editButton() -> some View {
        Button {
            let itemSelected = viewModel.itemSelected
            viewModel.newItemName = itemSelected.name
            viewModel.newItemRemoteImageUrl = itemSelected.image
            viewModel.newItemLink = itemSelected.itemLink
            viewModel.newItemDescription = itemSelected.description
            viewModel.newItemPrice = itemSelected.price ?? ""
            viewModel.showBottomSheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.showEditItemSheet = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                Text("Edit this item")
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    @ViewBuilder
    func bottomSheetButton(
        title: String,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(fill)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
            Text(title)
                .font(.wishies(.bold, 15))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onTapGesture {
            action()
        }
    }
}
