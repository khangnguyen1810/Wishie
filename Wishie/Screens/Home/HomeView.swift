//
//  HomeView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 14/10/25.
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
    @Namespace private var heroCardAnimation
    @State private var selectedWishlist: (WishlistModel, UserModel)?
    @State private var isShowWishlistDetail: Bool = false
    @State private var showDeleteConfirm = false
    @State private var showLeaveConfirm = false
    @AppStorage(WishieConstants.hasSeenHomeTutorial) private var hasSeenHomeTutorial: Bool = false
    @State private var homeAppeared: Bool = false
    @State private var heroProgress: CGFloat = 0
    @State private var heroHeight: CGFloat = 170 // approximate expanded height, corrected once measured
    private let heroCollapseDistance: CGFloat = 60 // scroll distance (pt) over which the hero fully collapses
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

    private var exampleWishlistForTutorial: (WishlistModel, UserModel) {
        let userId = UUID().uuidString
        let exampleWishlist = WishlistModel(
            id: "tutorial-example",
            name: "My Birthday Party",
            description: "Swipe left on this item to see options",
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            items: [
                WishlistItem(
                    id: "item1",
                    name: "Example Gift",
                    description: "",
                    image: nil,
                    pickedUserId: nil,
                    isPicked: false,
                    localImage: nil,
                    itemLink: ""
                )
            ],
            themeColor: "coral",
            userCreateId: userId,
            members: [userId: .owner], ownerName: ""
        )
        return (exampleWishlist, authViewModel.userInfo)
    }

    private var isEmpty: Bool {
        currentWishlists.isEmpty
    }

    private var highlightedWishlist: (WishlistModel, UserModel)? {
        let today = Calendar.current.startOfDay(for: Date())
        return currentWishlists
            .filter { Calendar.current.startOfDay(for: $0.0.dueDate) >= today }
            .min { $0.0.dueDate < $1.0.dueDate }
    }

    var body: some View {
        NavigationStack(path: $path) {
            BaseWishieScreen(
                background: {
                    HomeBackgroundDecoration()
                },
                topBar: {
                    HomeTopBar(
                        firstName: authViewModel.userInfo.firstName,
                        homeAppeared: homeAppeared,
                        onAddTapped: { activeSheet = .add },
                        onProfileTapped: { isShowProfile = true }
                    )
                },
                content: {
                    HomeTabSelector(selectedTab: $selectedTab, animation: animation)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                        .opacity(homeAppeared ? 1 : 0)
                        .offset(y: homeAppeared ? 0 : 26)
                        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.18), value: homeAppeared)
                        .padding(.bottom, 14)
                        .padding(.horizontal, 10)
                    if isEmpty {
                        HomeEmptyState(
                            msg: selectedTab == .myList
                                ? "You haven't created any wishlist yet."
                                : "You haven't joined to any wishlist yet.",
                            buttonTitle: selectedTab == .myList
                                ? "Create wishlist"
                                : "Join wishlist",
                            selectedTab: selectedTab,
                            action: {
                                if selectedTab == .myList {
                                    path.append(Route.createNew)
                                    activeSheet = nil
                                } else {
                                    path.append(Route.scanQRCode)
                                    activeSheet = nil
                                }
                            },
                            onRefresh: {
                                Task { await homeViewModel.getListWishlist() }
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        wishlistScrollContent
                    }
                },
                contentPadding: 0
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
                case .wishListInfoScreen(let preview):
                    WishListInformationView(preview: preview, path: $path)
                case .editWishlistInfo(wishlistId: let id):
                    EditWishlistInfoView(wishlistId: id)
                case .wishListDetailScreen(wishlistId: let id, isFromInfo: let isFromInfo):
                    WishlistDetailView(
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
                await homeViewModel.getListWishlist()
            }
            .onAppear {
                homeAppeared = true
            }
            .onDisappear {
                homeAppeared = false
            }
        }
        .sheet(item: $activeSheet) { type in
            HomeAddSheet(
                type: type,
                onScanQR: {
                    path.append(Route.scanQRCode)
                    activeSheet = nil
                },
                onCreateNew: {
                    path.append(Route.createNew)
                    activeSheet = nil
                }
            )
            .presentationDetents([.fraction(0.2)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowProfile) {
            ProfileView()
                .environmentObject(authViewModel)
        }
        .overlayPreferenceValue(CoachMarkBoundsKey.self) { anchors in
            if !hasSeenHomeTutorial {
                HomeTutorialOverlayView(
                    anchors: anchors,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hasSeenHomeTutorial = true
                        }
                    }
                )
            }
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
        .showFullScreenDialog($authViewModel.isShowProgress)
    }

    @ViewBuilder
    private var wishlistScrollContent: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 6) {
                    if highlightedWishlist != nil {
                        Color.clear.frame(height: heroHeight + 5)
                    }
                    if !hasSeenHomeTutorial {
                        HomeItemViewCell(item: exampleWishlistForTutorial)
                            .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeExampleItem": $0] }
                            .allowsHitTesting(false)
                            .opacity(0.95)
                    } else {
                        switch selectedTab {
                        case .myList:
                            ForEach(Array(homeViewModel.myWishlists.enumerated()), id: \.element.0) { index, wishlist in
                                WishlistRow(
                                    wishlist: wishlist,
                                    index: index,
                                    animation: animation,
                                    path: $path,
                                    homeAppeared: homeAppeared,
                                    heroHeight: heroProgress
                                ) {
                                    Button {
                                        path.append(Route.editWishlistInfo(wishlistId: wishlist.0.id))
                                    } label: {
                                        Label("Change info", systemImage: "pencil")
                                    }
                                    Button {
                                        Task { await homeViewModel.archiveWishlist(wishlistId: wishlist.0.id) }
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    Button(role: .destructive) {
                                        selectedWishlist = wishlist
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                
                            }
                        case .friendsList:
                            ForEach(Array(homeViewModel.myFriendWishlists.enumerated()), id: \.element.0) { index, wishlist in
                                WishlistRow(
                                    wishlist: wishlist,
                                    index: index,
                                    animation: animation,
                                    path: $path,
                                    homeAppeared: homeAppeared,
                                    heroHeight: heroProgress
                                ) {
                                    Button(role: .destructive) {
                                        selectedWishlist = wishlist
                                        showLeaveConfirm = true
                                    } label: {
                                        Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newValue in
                heroProgress = min(max(newValue / heroCollapseDistance, 0), 1)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await homeViewModel.getListWishlist()
            }

            if let highlighted = highlightedWishlist {
                HomeHeroCard(
                    wishlist: highlighted,
                    progress: heroProgress,
                    path: $path,
                    animation: heroCardAnimation,
                    selectedTab: selectedTab,
                    statusOwner: selectedTab == .myList ? authViewModel.userInfo : highlighted.1,
                    homeAppeared: homeAppeared
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                if heroProgress <= 0.01 { heroHeight = proxy.size.height }
                            }
                            .onChange(of: proxy.size.height) { _, newValue in
                                if heroProgress <= 0.01 { heroHeight = newValue }
                            }
                    }
                )
            }
        }
    }
}
