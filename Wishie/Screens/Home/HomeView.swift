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
    var body: some View {
        NavigationStack(path: $path) {
            BaseWishieScreen(
                topBar: {
                    topAppBar()
                },
                content: {
                    HStack {
                        typeSegmentItem(title: "My list", tab: .myList)
                        typeSegmentItem(title: "Friend's list", tab: .friendsList)
                    }
                    .frame(height: 40)
                    
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.lightYellow.opacity(0.2))
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                    .padding(.bottom)
                    if isEmpty {
                        contentUnavailable(
                            msg: selectedTab == .myList
                            ? "You haven't created any wishlist yet."
                            : "You haven't joined to any wishlist yet.",
                            buttonTitle: selectedTab == .myList
                            ? "Create wishlist"
                            : "Join wishlist"
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
                        List {
                            switch selectedTab {
                            case .myList:
                                ForEach(homeViewModel.myWishlists, id: \.self.0) { wishlist in
                                    ZStack {
                                        NavigationLink {
                                            WishlistDetailScreen(
                                                navigationPath: $path,
                                                wishlist: wishlist.0 ,
                                                owner: wishlist.1
                                            )
                                            .navigationTransition(
                                                .zoom(
                                                    sourceID: wishlist.0.id,
                                                    in: animation
                                                )
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
                                                wishlist: wishlist.0 ,
                                                owner: wishlist.1
                                            )
                                            .navigationTransition(
                                                .zoom(
                                                    sourceID: wishlist.0.id,
                                                    in: animation
                                                )
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
                                        Button() {
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
    @ViewBuilder
    func typeSegmentItem(title: String, tab: HomeTab) -> some View {
        ZStack {
            if selectedTab == tab {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.lightYellow)
                    .matchedGeometryEffect(id: "TAB", in: animation)
            }
            
            Text(title)
                .font(.wishies(.bold, 17))
                .foregroundStyle(selectedTab == tab ? .black : .lightGrey)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
        }
        .onTapGesture { selectedTab = tab }
    }
    @ViewBuilder
    func wishListItem(item: (WishlistModel, UserModel)) -> some View {
        VStack {
            HStack {
                Text(item.0.name)
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.leading)
                    .font(.wishies(.bold, 17))
                Spacer()
                Text("\(item.1.firstName) \(item.1.lastName)")
                    .foregroundStyle(Color.black)
                    .font(.wishies(.regular, 15))
                    .truncationMode(.tail)
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
            }
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.0.description)
                        .font(.wishies(.italic, 14))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("end date: \(item.0.dueDate.toShortDateString())")
                        .font(.wishies(.regular, 14))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity,alignment: .leading)
                }
                Spacer()
                VStack {
                    let itemPicked = item.0.items.filter({ $0.isPicked })
                    if item.0.items.count > 0 {
                        let progress = Double(itemPicked.count) / Double(item.0.items.count)
                        GiftProgressView(progress: progress)
                        Text("\(itemPicked.count)/\(item.0.items.count) gifts")
                            .font(.wishies(.regular, 14))
                            .foregroundStyle(Color.darkGrey)
                    } else {
                        Text("0 gift")
                            .font(.wishies(.regular, 14))
                            .foregroundStyle(Color.darkGrey)
                    }
                }
                .frame(maxWidth: 100)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.sunset).opacity(0.5)
        }
    }
    
    @ViewBuilder
    func topAppBar() -> some View {
        TopAppBar  {
            Text("Are you gud? \(authViewModel.userInfo.firstName)")
                .font(.wishies(.bold, 25))
                .foregroundColor(.black)
        } trailing: {
            Circle()
                .fill(.lightYellow)
                .frame(width: 40, height: 40)
                .overlay(content: {
                    Image("add")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                })
                .onTapGesture {
                    activeSheet = .add
                }
                .padding(.trailing, 10)
            Circle()
                .fill(.lightYellow)
                .frame(width: 40, height: 40)
                .overlay(content: {
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                })
                .onTapGesture {
                    isShowProfile = true
                }
        }
    }
    @ViewBuilder
    func bottomSheet(type: SheetType) -> some View {
        ZStack {
            Color.lightYellow1.ignoresSafeArea()
            if type == .add {
                VStack(spacing: 20) {
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
            RoundedRectangle(cornerRadius: 15)
                .fill(.lightYellow)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            HStack {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                    .padding(.leading, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(title)
                .font(.wishies(.bold, 20))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    @ViewBuilder
    func contentUnavailable(
        msg: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack {
            Image(systemName: "tray.fill")
                .resizable()
                .foregroundStyle(.black)
                .scaledToFit()
                .frame(width: 50, height: 50)
            Text(msg)
                .font(Font.wishies(.bold, 25))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.vertical,20)
            WishieButton(
                title: buttonTitle,
                enabled: true,
                width: 250,
                height: 50) {
                    action()
                }
            Text("Refresh")
                .font(.wishies(.regular, 15))
                .foregroundStyle(.wishiePink)
                .onTapGesture {
                    Task {
                        await homeViewModel.getListWishlist()
                    }
                }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}


struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

