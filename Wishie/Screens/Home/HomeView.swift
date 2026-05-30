//
//  HomeView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 14/10/25.
//

import SwiftUI

enum SheetType: String, Identifiable {
    case add
    var id: String { self.rawValue }
}

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var homeViewModel: HomeViewModel = HomeViewModel()
    @State private var isShowError = false
    @State private var isShowLoading = false
    @State private var sheetHeight: CGFloat = .zero
    @State private var path = NavigationPath()
    @State private var activeSheet: SheetType?
    @State private var isShowProfile: Bool = false
    @Namespace private var animation
    @State private var selectedWishlist: (WishlistModel, UserModel)?
    @State private var isShowWishlistDetail: Bool = false
    @State private var showDeleteConfirm = false
    @State private var showLeaveConfirm = false
    enum HomeTab {
        case myList
        case friendsList
    }
    @State private var selectedTab: HomeTab = .myList
    private var currentWishlists: [(WishlistModel, UserModel)] {
        switch selectedTab {
        case .myList:
            return homeViewModel.myWishlists
        case .friendsList:
            return homeViewModel.myFriendWishlists
        }
    }
    
    private var isEmpty: Bool {
        currentWishlists.isEmpty
    }

    private var totalGifts: Int {
        currentWishlists.reduce(0) { $0 + $1.0.items.count }
    }

    private var pickedGifts: Int {
        currentWishlists.reduce(0) { $0 + $1.0.items.filter { $0.isPicked }.count }
    }

    private var nearestDueDate: Date? {
        let today = Calendar.current.startOfDay(for: Date())
        return currentWishlists
            .map { $0.0.dueDate }
            .filter { Calendar.current.startOfDay(for: $0) >= today }
            .min()
    }

    var body: some View {
        NavigationStack(path: $path) {
            BaseWishieScreen(
                topBar: {
                    topAppBar()
                },
                content: {
                    tabSelector
                        .frame(height: 44)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.4))
                                .overlay(
                                    Capsule().stroke(Color(hex: "#F1D790").opacity(0.6), lineWidth: 1)
                                )
                        }
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                        .padding(.bottom, 14)
                    if isEmpty {
                        contentUnavailable(
                            msg: selectedTab == .myList
                                ? "You haven't created any wishlist yet."
                                : "You haven't joined to any wishlist yet.",
                            buttonTitle: selectedTab == .myList
                                ? "Create wishlist"
                                : "Join wishlist",
                            selectedTab: selectedTab
                        ) {
                            if selectedTab == .myList {
                                path.append(Route.createNew)
                                activeSheet = nil
                            } else {
                                path.append(Route.scanQRCode)
                                activeSheet = nil
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        summaryCard()
                            .padding(.bottom, 12)
                        List {
                            switch selectedTab {
                            case .myList:
                                ForEach(homeViewModel.myWishlists, id: \.self.0) { wishlist in
                                    ZStack {
                                        NavigationLink {
                                            WishlistDetailScreen(
                                                navigationPath: $path,
                                                wishlist: wishlist.0,
                                                owner: wishlist.1
                                            )
                                            .navigationTransition(
                                                .zoom(sourceID: wishlist.0.id, in: animation)
                                            )
                                        } label: {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        HomeItemViewCell(item: wishlist)
                                    }
                                    .contentShape(Rectangle())
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .swipeActions {
                                        Button {
                                            selectedWishlist = wishlist
                                            showDeleteConfirm = true
                                        } label: {
                                            Label("Delete wishlist", systemImage: "trash")
                                        }
                                        .tint(.wishiePink)
                                    }
                                }
                            case .friendsList:
                                ForEach(homeViewModel.myFriendWishlists, id: \.self.0) { wishlist in
                                    ZStack {
                                        NavigationLink {
                                            WishlistDetailScreen(
                                                navigationPath: $path,
                                                wishlist: wishlist.0,
                                                owner: wishlist.1
                                            )
                                            .navigationTransition(
                                                .zoom(sourceID: wishlist.0.id, in: animation)
                                            )
                                        } label: {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        HomeItemViewCell(item: wishlist)
                                    }
                                    .contentShape(Rectangle())
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .swipeActions {
                                        Button {
                                            selectedWishlist = wishlist
                                            showLeaveConfirm = true
                                        } label: {
                                            Label("Leave Wishlist", systemImage: "trash")
                                        }
                                        .tint(.wishiePink)
                                    }
                                }
                            }
                        }
                        .listRowSpacing(10)
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .refreshable {
                            await homeViewModel.getListWishlist()
                        }
                    }
                }
            )
            .navigationDestination(for: Route.self) { path in
                switch path {
                case .createNew:
                    CreateWishListScreen(path: $path)
                case .scanQRCode:
                    ScanQRScreen(path: $path)
                case .createSuccess(wishListId: let id):
                    CreateWishlistSuccessScreen(path: $path, wishlistId: id)
                case .qrCodeScreen(wishlistId: let id):
                    WishlistQRCodeView(wishlistId: id)
                case .wishListInfoScreen(wishlistId: let id):
                    WishListInformationView(wishlistId: id, path: $path)
                case .wishListDetailScreen(wishlistId: let id, isFromInfo: let isFromInfo):
                    WishlistDetailScreen(
                        navigationPath: $path,
                        wishlistId: id,
                        isFromInfo: isFromInfo
                    )
                default:
                    EmptyView()
                }
            }
            .task {
                await authViewModel.getUserInfo()
                if (
                    homeViewModel.myWishlists.isEmpty && homeViewModel.myFriendWishlists.isEmpty
                ) {
                    await homeViewModel.getListWishlist()
                }
            }
        }
        .sheet(item: $activeSheet) { type in
            bottomSheet(type: type)
                .presentationDetents([.fraction(0.2)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowProfile) {
            ProfileView()
                .environmentObject(authViewModel)
        }
        .showDialogIfNeeded(
            $isShowError, title: "You want to leave?",
            message: "You can login again later, please come back :3",
            onOk:  {
                authViewModel.logOut()
            }
        )
        .showDialogIfNeeded($showDeleteConfirm, title: "Are you sure to delete it?", message: "When you delete this wishlist, you can't recover it again.", onOk: {
            Task {
                guard let wishlist = selectedWishlist else { return }
                await homeViewModel.deleteWishlist(wishlistId: wishlist.0.id)
            }
            showDeleteConfirm = false
        }, onCancel: {
            showDeleteConfirm = false
        })
        .showDialogIfNeeded($showLeaveConfirm, title: "Are you sure to leave this wishlist?", message: "You can join this wishlist later, please come back :3", onOk: {
            Task {
                guard let wishlist = selectedWishlist else { return }
                await homeViewModel.leaveWishlist(wishlistId: wishlist.0.id)
            }
            showLeaveConfirm = false
        }, onCancel: {
            showLeaveConfirm = false
        })
        .showFullScreenDialog($homeViewModel.isGettingList)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabItem(title: "My list", tab: .myList)
            tabItem(title: "Friend's list", tab: .friendsList)
        }
    }

    @ViewBuilder
    private func tabItem(title: String, tab: HomeTab) -> some View {
        ZStack {
            if selectedTab == tab {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .matchedGeometryEffect(id: "TAB", in: animation)
            }
            Text(title)
                .font(.wishies(.bold, 15))
                .foregroundStyle(selectedTab == tab ? .black : Color.darkGrey)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
        }
        .onTapGesture { selectedTab = tab }
    }

    @ViewBuilder
    func summaryCard() -> some View {
        HStack(spacing: 0) {
            summaryStatItem(
                value: "\(currentWishlists.count)",
                label: selectedTab == .myList ? "Wishlists" : "Joined",
                icon: "list.star"
            )
            Divider()
                .frame(height: 28)
                .background(Color(hex: "#F1D790").opacity(0.8))
            summaryStatItem(
                value: "\(pickedGifts)/\(totalGifts)",
                label: "Gifts Picked",
                icon: "gift.fill"
            )
            nearestEventSection()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7").opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        }
        .shadow(color: Color(hex: "#F1D790").opacity(0.3), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private func nearestEventSection() -> some View {
        if let nearest = nearestDueDate {
            let days = max(0, Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: nearest)
            ).day ?? 0)
            Divider()
                .frame(height: 28)
                .background(Color(hex: "#F1D790").opacity(0.8))
            summaryStatItem(
                value: days == 0 ? "Today!" : "\(days)d",
                label: "Next Event",
                icon: "party.popper.fill"
            )
        }
    }

    @ViewBuilder
    private func summaryStatItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wishiePink)
                Text(value)
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(Color.black)
            }
            Text(label)
                .font(.wishies(.regular, 11))
                .foregroundStyle(Color.darkGrey)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func topAppBar() -> some View {
        TopAppBar {
            VStack(alignment: .leading, spacing: 3) {
                Text(authViewModel.userInfo.firstName.isEmpty
                     ? "Hey there! \u{1F381}"
                     : "Hey, \(authViewModel.userInfo.firstName)! \u{1F389}")
                    .font(.wishies(.bold, 22))
                    .foregroundColor(.black)
                Text("Your celebrations await \u{2728}")
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(Color.darkGrey)
            }
        } trailing: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#F1D790")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .shadow(color: Color(hex: "#F9C46B").opacity(0.45), radius: 6, x: 0, y: 3)
                    Image("add")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .onTapGesture { activeSheet = .add }
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                        )
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .onTapGesture { isShowProfile = true }
            }
            .padding(.trailing, 4)
        }
    }

    @ViewBuilder
    func bottomSheet(type: SheetType) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            if type == .add {
                VStack(spacing: 16) {
                    Text("What would you like to do?")
                        .font(.wishies(.bold, 16))
                        .foregroundStyle(Color.darkGrey)
                        .padding(.top, 8)
                    bottomSheetOption(image: "qr_icon", title: "Scan QR code")
                        .onTapGesture {
                            path.append(Route.scanQRCode)
                            activeSheet = nil
                        }
                    bottomSheetOption(image: "create_new_icon", title: "Create new wishlist")
                        .onTapGesture {
                            path.append(Route.createNew)
                            activeSheet = nil
                        }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    func bottomSheetOption(image: String, title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#F1D790")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                        .padding(.leading, 8)
                }
                .padding(.leading, 12)
                Text(title)
                    .font(.wishies(.bold, 16))
                    .foregroundStyle(Color.black)
                    .padding(.leading, 10)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.darkGrey)
                    .padding(.trailing, 16)
            }
        }
    }

    @ViewBuilder
    func contentUnavailable(
        msg: String,
        buttonTitle: String,
        selectedTab: HomeTab,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FEF3D7"), Color(hex: "#F9C46B")],
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
            VStack(spacing: 8) {
                Text(selectedTab == .myList ? "Your wishlist is waiting..." : "No events joined yet")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)
                Text(msg)
                    .font(.wishies(.regular, 14))
                    .foregroundStyle(Color.darkGrey)
                    .multilineTextAlignment(.center)
            }
            WishieButton(
                title: buttonTitle,
                enabled: true,
                filColor: Color(hex: "#F1D790"),
                width: 220,
                height: 48
            ) {
                action()
            }
            Button {
                Task { await homeViewModel.getListWishlist() }
            } label: {
                Text("Refresh")
                    .font(.wishies(.regular, 14))
                    .foregroundStyle(Color.wishiePink)
            }
        }
        .padding(40)
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

