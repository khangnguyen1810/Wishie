//
//  WishlistDetailScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 18/3/26.
//

import SwiftUI
import DotLottie
import SDWebImageSwiftUI

private struct SheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    var currentUserId: String? {
        UserDefaults.standard.string(forKey: WishieConstants.userIdKey)
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
                VStack (spacing: 20) {
                    headerContent()
                        .padding(.horizontal, 15)
                        .padding(.top, 15)
                    if let mostDesiredItem = viewModel.currentMostDesiredItem {
                        mostDesiredSection(item: mostDesiredItem)
                            .padding(.horizontal, 15)
                    }
                    listContent()
                }
                .padding(.bottom, 100)
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
                .onPreferenceChange(SheetHeightPreferenceKey.self) { height in
                    sheetHeight = height
                }
                .presentationDetents([.height(sheetHeight)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(26)
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
            $viewModel.showReplaceMostDesiredConfirmation,
            title: "Replace most desired?",
            message: "\"\(viewModel.currentMostDesiredItem?.name ?? "")\" is currently your most desired gift. Marking \"\(viewModel.itemSelected.name)\" will replace it.",
            showCancel: true,
            onOk: {
                Task {
                    await viewModel.setDesired(
                        wishlistId: viewModel.wishlistInfo.id,
                        isDesired: true
                    )
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
                HStack(spacing: 6) {
                    Text("🎁")
                        .font(.system(size: 20))
                    Text("\(totalCount) items")
                        .font(.wishies(.bold, 16))
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
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.lightYellow1)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }

    @ViewBuilder
    func mostDesiredSection(item: WishlistItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("🌟")
                    .font(.system(size: 14))
                Text("Most Desired")
                    .font(.wishies(.bold, 14))
                    .foregroundStyle(Color(hex: "#5B3F0F"))
            }
            TopPickCard(item: item) {
                viewModel.itemSelected = item
                viewModel.showBottomSheet = true
            }
            .equatable()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func listContent() -> some View {
        let items = viewModel.wishlistInfo.items
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        VStack(alignment: .leading, spacing: 10) {
            Text("All Wishes · \(items.count)")
                .font(.wishies(.bold, 14))
                .foregroundStyle(Color(hex: "#5B3F0F"))
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items, id: \.self) { item in
                    gridItemCard(item: item)
                }
            }
        }
        .padding(.horizontal, 15)
    }

    @ViewBuilder
    func gridItemCard(item: WishlistItem) -> some View {
        let accent = Color(hex: viewModel.wishlistInfo.theme.secondary)
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: viewModel.wishlistInfo.theme.primary).lightened(by: 0.8))
                    .frame(height: 64)
                    .overlay {
                        WebImage(url: URL(string: item.image ?? ""), content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                        }, placeholder: {
                            DotLottieAnimation(
                                fileName: "giftloading",
                                config: AnimationConfig(autoplay: true, loop: true)
                            )
                            .view()
                            .frame(width: 30, height: 30)
                        })
                        .frame(width: 44, height: 44)
                    }
                if item.isPicked {
                    HStack(spacing: 3) {
                        Text("🎁")
                            .font(.system(size: 9.5))
                        Text("Picked")
                            .font(.wishies(.bold, 9.5))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accent))
                    .padding(8)
                }
            }
            Text(item.name)
                .font(.wishies(.bold, 13.5))
                .foregroundStyle(Color(hex: "#3B2A0F"))
                .lineLimit(1)
                .padding(.top, 8)
            if let price = item.price, !price.isEmpty {
                Text(price)
                    .font(.wishies(.bold, 12))
                    .foregroundStyle(Color(hex: "#8C7A5A"))
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(
                    color: item.isPicked
                        ? accent.opacity(0.18)
                        : Color(hex: "#B48C3C").opacity(0.08),
                    radius: item.isPicked ? 9 : 7,
                    x: 0,
                    y: item.isPicked ? 8 : 6
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    item.isPicked ? accent : Color(hex: "#F1E4C4"),
                    lineWidth: item.isPicked ? 2 : 1
                )
        )
        .onTapGesture {
            viewModel.itemSelected = item
            viewModel.showBottomSheet = true
        }
    }
    @ViewBuilder
    func bottomSheet() -> some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color(hex: "#E9DCC0"))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)

            itemImageBlock()
            itemTextBlock()

            if wishlist?.isOwner() == true {
                ownerActionsRow()
            } else {
                nonOwnerActionsRow()
            }

            Rectangle()
                .fill(Color(hex: "#EFE4C8"))
                .frame(height: 1)

            if wishlist?.isOwner() == true {
                deleteItemRow()
            } else {
                reserveCTAButton()
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 22)
        .background(Color.white)
        .overlay(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SheetHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
    }

    @ViewBuilder
    func itemImageBlock() -> some View {
        let placeholderColor = Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.85)
        Group {
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                WebImage(url: URL(string: viewModel.itemSelected.image ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }, placeholder: {
                    placeholderColor
                        .overlay {
                            DotLottieAnimation(
                                fileName: "giftloading",
                                config: AnimationConfig(autoplay: true, loop: true)
                            )
                            .view()
                            .frame(width: 40)
                        }
                })
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(placeholderColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .topTrailing) {
            Button {
                viewModel.showBottomSheet = false
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 30, height: 30)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "#8C7A5A"))
                }
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .overlay(alignment: .bottomLeading) {
            if viewModel.itemSelected.isPicked {
                pickedStatusPill()
                    .padding(10)
            }
        }
    }

    @ViewBuilder
    func itemTextBlock() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(viewModel.itemSelected.name)
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(Color(hex: "#2A1E0B"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let price = viewModel.itemSelected.price, !price.isEmpty {
                    Text(price)
                        .font(.wishies(.bold, 16))
                        .foregroundStyle(Color(hex: "#38B7B0"))
                        .fixedSize()
                }
            }
            if !viewModel.itemSelected.description.isEmpty {
                Text(viewModel.itemSelected.description)
                    .font(.wishies(.regular, 13.5))
                    .foregroundStyle(Color(hex: "#5B4A32"))
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func pickedStatusPill() -> some View {
        let isPickedByMe = viewModel.itemSelected.pickedUserId != nil && viewModel.itemSelected.pickedUserId == currentUserId
        let textColor = isPickedByMe ? Color(hex: "#1F8F89") : Color(hex: viewModel.wishlistInfo.theme.secondary)
        HStack(spacing: 6) {
            Text("🎁")
                .font(.system(size: 11))
            Text(isPickedByMe ? "Picked by you" : "Picked")
                .font(.wishies(.bold, 11.5))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.92)))
    }

    @ViewBuilder
    func mostDesiredCTAButton() -> some View {
        let selectedItem = viewModel.itemSelected
        HStack(spacing: 7) {
            Image("most_desired_icon")
                .resizable()
                .frame(width: 25, height: 25)
            Text( selectedItem.isMostDesired ? "Remove Most Desired": "Most Desired")
                .font(.wishies(.bold, 13))
        }
        .foregroundStyle(Color(hex: "#6B4A0E"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FFD66B"), Color(hex: "#F3B23A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: "#E6AA32").opacity(0.3), radius: 8, x: 0, y: 8)
        .onTapGesture {
            if viewModel.wouldReplaceMostDesired {
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showReplaceMostDesiredConfirmation = true
                }
                return
            }
            Task {
                await viewModel.setDesired(
                    wishlistId: viewModel.wishlistInfo.id,
                    isDesired: !viewModel.itemSelected.isMostDesired
                )
                viewModel.showBottomSheet = false
            }
        }
    }

    @ViewBuilder
    func squareIconButton(systemIcon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#F7F1E3"))
                    .frame(width: 46, height: 46)
                Image(systemName: systemIcon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "#5B4A32"))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func ownerActionsRow() -> some View {
        HStack(spacing: 10) {
            mostDesiredCTAButton()
            squareIconButton(systemIcon: "pencil") {
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
            }
            squareIconButton(systemIcon: "link") {
                viewModel.openProductLink()
            }
        }
    }

    @ViewBuilder
    func nonOwnerActionsRow() -> some View {
            ZStack {
                HStack {
                    Image(systemName: "link")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Link")
                    .font(.wishies(.bold, 13))
            }
            .foregroundStyle(Color(hex: "#6B4A0E"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#F7F1E3"))
            }
            .onTapGesture {
                viewModel.openProductLink()
            }
    }

    @ViewBuilder
    func deleteItemRow() -> some View {
        let isDisabled = viewModel.itemSelected.isPicked
        HStack(spacing: 8) {
            Image(systemName: "trash")
                .font(.system(size: 15, weight: .semibold))
            Text("Delete item")
                .font(.wishies(.bold, 14))
        }
        .foregroundStyle(isDisabled ? Color.darkGrey : Color(hex: "#D9375A"))
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isDisabled else { return }
            viewModel.showBottomSheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.showDeleteConfirmation = true
            }
        }
    }

    @ViewBuilder
    func reserveCTAButton() -> some View {
        let isDisabled = viewModel.itemSelected.isPicked
        Text("Reserve")
            .font(.wishies(.bold, 14.5))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                Capsule().fill(isDisabled ? Color.lightGrey : Color.wishiePink)
            )
            .onTapGesture {
                guard !isDisabled else { return }
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showReserveConfirmation = true
                }
            }
    }
}
