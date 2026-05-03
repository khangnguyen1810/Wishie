//
//  HomeView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 14/10/25.
//

import SwiftUI



struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isShowError = false
    @State private var isShowLoading = false
    @State private var showBottomSheet = false
    @State private var sheetHeight: CGFloat = .zero
    @State private var path = NavigationPath()
    @State private var typeSheet: String = ""
    @Namespace private var animation
    enum HomeTab {
        case myList
        case friendsList
    }
    @State private var selectedTab: HomeTab = .myList
    var body: some View {
        NavigationStack(path: $path) {
            BaseWishieScreen(
                topBar: {
                    TopAppBar  {
                        Text("Are you gud?")
                            .font(.wishies(.bold, 30))
                            .foregroundColor(.black)
                    } trailing: {
                        Circle()
                            .fill(.lightYellow)
                            .frame(width: 50, height: 50)
                            .overlay(content: {
                                Image("add")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30)
                            })
                            .onTapGesture {
                                typeSheet = "Add"
                                showBottomSheet = true
                            }
                            .padding(.trailing, 10)
                        Circle()
                            .fill(.lightYellow)
                            .frame(width: 50, height: 50)
                            .overlay(content: {
                                Image("user")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30)
                            })
                            .onTapGesture {
                                typeSheet = "User"
                                showBottomSheet = true
                            }
                    }
                    
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
                    ScrollView() {
                        VStack(spacing: 10) {
                            switch selectedTab {
                            case .myList:
                                
                                wishListItem(item: <#WishlistModel#>)
                            case .friendsList:
                                ForEach(0..<10) { _ in
                                    wishListItem()
                                        .redacted(reason: .placeholder)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            )
            .onTapGesture {
                if (showBottomSheet == true) {
                    showBottomSheet = false
                }
            }
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
                }
            }
            .task {
                viewm
            }
        }
        .sheet(isPresented: $showBottomSheet, content: {
            bottomSheet()
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    sheetHeight = newHeight
                }
                .presentationDetents([.height(sheetHeight)])
        })
        .showDialogIfNeeded(
            $isShowError, title: "You want to leave?",
            message: "You can login again later, please come back :3",
            onOk:  {
                showBottomSheet = false
                authViewModel.logOut()
            }
        )
        .showFullScreenDialog($authViewModel.isShowProgress)
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
    func wishListItem(item: WishlistModel) -> some View {
        VStack {
            HStack {
                Text(item.name)
                    .font(.wishies(.bold, 17))
                Spacer()
                Text(item.userCreateId)
                    .font(.wishies(.regular, 15))
                    .truncationMode(.tail)
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
            }
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.description)
                        .font(.wishies(.italic, 14))
                        .frame(width: UIScreen.main.bounds.width * 0.6)
                        .frame(maxHeight: 60, alignment: .topLeading)
                    Text("end date: \(item.dueDate)")
                        .font(.wishies(.regular, 14))
                        .frame(maxWidth: .infinity,alignment: .leading)
                }
                
                Spacer()
                VStack {
                    GiftProgressView(progress: 1/4)
                    Text("1/4 gifts")
                        .font(.wishies(.regular, 14))
                        .foregroundStyle(Color.darkGrey)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [
                        .wishiePink.opacity(0.5),
                        .lightYellow1.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                )
        }
    }
    
    @ViewBuilder
    func topAppBar() -> some View {
        HStack {
            Text("Are you gud?")
                .font(.wishies(.bold, 30))
                .foregroundColor(.black)
            Spacer()
            Circle()
                .fill(.lightYellow)
                .frame(width: 50, height: 50)
                .overlay(content: {
                    Image("add")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                })
                .onTapGesture {
                    showBottomSheet = true
                }
                .padding(.trailing, 10)
            Circle()
                .fill(.lightYellow)
                .frame(width: 50, height: 50)
                .overlay(content: {
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                })
                .onTapGesture {
                    isShowError = true
                }
        }
    }
    @ViewBuilder
    func bottomSheet() -> some View {
        ZStack {
            Color.lightYellow1.ignoresSafeArea()
            if typeSheet == "Add" {
                VStack(spacing: 20) {
                    bottomSheetOption(image: "qr_icon", title: "Scan QR code")
                        .onTapGesture {
                            showBottomSheet = false
                            path.append(Route.scanQRCode)
                        }
                    bottomSheetOption(image: "create_new_icon", title: "Create new wishlist")
                        .onTapGesture {
                            showBottomSheet = false
                            path.append(Route.createNew)
                        }
                }
                .padding()
            } else if typeSheet == "User" {
                bottomSheetOption(image: "log_out", title: "Log out")
                    .padding()
                    .onTapGesture {
                        showBottomSheet = false
                        isShowError = true
                    }
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
}


struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

