//
//  HomeView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 14/10/25.
//

import SwiftUI
import DotLottie

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
    @State private var isRefreshing = false
    @AppStorage(WishieConstants.hasSeenHomeTutorial) private var hasSeenHomeTutorial: Bool = false
    @State private var homeAppeared: Bool = false
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

    private var currentUserId: String? {
        UserDefaults.standard.string(forKey: WishieConstants.userIdKey)
    }

    private var headerSubtitle: String {
        HomeCardSummary.subtitle(
            isMyList: selectedTab == .myList,
            mine: homeViewModel.myWishlists.map(\.0),
            friends: homeViewModel.myFriendWishlists.map(\.0)
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            BaseWishieScreen(
                background: {
                    Color.obScreenBg
                },
                topBar: {
                    HomeTopBar(
                        firstName: authViewModel.userInfo.firstName,
                        subtitle: headerSubtitle,
                        homeAppeared: homeAppeared,
                        onAddTapped: { activeSheet = .add },
                        onProfileTapped: { isShowProfile = true },
                        avatarUrl: authViewModel.userInfo.avatarUrl ?? ""
                    )
                },
                content: {
                    HomeTabSelector(selectedTab: $selectedTab, animation: animation)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                        .opacity(homeAppeared ? 1 : 0)
                        .offset(y: homeAppeared ? 0 : 26)
                        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.18), value: homeAppeared)
                        .padding(.top, 8)
                        .padding(.bottom, 18)
                        .padding(.horizontal, 16)
                    Group {
                        if isEmpty {
                            HomeEmptyState(
                                selectedTab: selectedTab,
                                action: {
                                    path.append(selectedTab == .myList ? Route.createNew : Route.scanQRCode)
                                    activeSheet = nil
                                },
                                onRefresh: refreshList
                            )
                        } else {
                            wishlistScrollContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                case .editWishlistInfo(wishlistId: let id, user: let user):
                    EditWishlistInfoView(wishlistId: id, user: user)
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
        .showDialogIfNeeded($homeViewModel.isShowError, title: "Something went wrong", message: homeViewModel.errorMessage)
    }

    /// Pull-to-refresh. Runs in an unstructured Task so SwiftUI cancelling the refreshable
    /// action doesn't propagate into the network request.
    private func refreshList() async {
        await Task { await homeViewModel.getListWishlist(showLoading: false) }.value
    }

    @ViewBuilder
    private var wishlistScrollContent: some View {
        let split = HomeCardSummary.splitFeatured(currentWishlists) { $0.0 }
        let isOwnList = selectedTab == .myList
        ScrollView {
            LazyVStack(spacing: 14) {
                if isRefreshing {
                    DotLottieAnimation(
                        fileName: "giftloading",
                        config: AnimationConfig(autoplay: true, loop: true)
                    )
                    .view()
                    .frame(width: 56, height: 56)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                if !hasSeenHomeTutorial {
                    HomeCompactCard(
                        wishlist: exampleWishlistForTutorial.0,
                        owner: exampleWishlistForTutorial.1,
                        isOwnList: true,
                        currentUserId: currentUserId
                    )
                    .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeExampleItem": $0] }
                    .allowsHitTesting(false)
                    .opacity(0.95)
                } else {
                    if let featured = split.featured {
                        WishlistRow(
                            wishlist: featured,
                            index: 0,
                            animation: animation,
                            path: $path,
                            homeAppeared: homeAppeared
                        ) {
                            HomeFeaturedCard(
                                wishlist: featured.0,
                                owner: featured.1,
                                isOwnList: isOwnList,
                                currentUserId: currentUserId
                            )
                        } contextMenu: {
                            contextMenu(for: featured)
                        }
                    }
                    ForEach(Array(split.rest.enumerated()), id: \.element.0.id) { index, wishlist in
                        WishlistRow(
                            wishlist: wishlist,
                            index: index + 1,
                            animation: animation,
                            path: $path,
                            homeAppeared: homeAppeared
                        ) {
                            HomeCompactCard(
                                wishlist: wishlist.0,
                                owner: wishlist.1,
                                isOwnList: isOwnList,
                                currentUserId: currentUserId
                            )
                        } contextMenu: {
                            contextMenu(for: wishlist)
                        }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            withAnimation(.easeOut(duration: 0.2)) { isRefreshing = true }
            await refreshList()
            withAnimation(.easeIn(duration: 0.2)) { isRefreshing = false }
        }
    }

    @ViewBuilder
    private func contextMenu(for wishlist: (WishlistModel, UserModel)) -> some View {
        switch selectedTab {
        case .myList:
            Button {
                path.append(Route.editWishlistInfo(wishlistId: wishlist.0.id, user: wishlist.1))
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
        case .friendsList:
            Button(role: .destructive) {
                selectedWishlist = wishlist
                showLeaveConfirm = true
            } label: {
                Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}
