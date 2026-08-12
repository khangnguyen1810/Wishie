//
//  CreateWishListScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 13/12/25.
//

import SwiftUI

struct CreateWishListScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var createWishlistViewModel = CreateWishlistViewModel()
    @State private var progressTabIndex: Int = 0
    @Binding var path: NavigationPath
    @State private var errorMessage: String = ""
    @State private var creating: Bool = false
    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 40, height: 40)
                    .overlay(content: {
                        Image("back_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17)
                    })
                    .onTapGesture {
                        dismiss()
                    }
                    .padding(.trailing, 10)
            } center: {
                Text("Create new wishlist")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            ZStack {
                VStack {
                    stepProgress()
                        .padding(.top,20)
                        .padding(.bottom,50)
                    switch progressTabIndex {
                    case 0:
                        CreateWishlistPage1()
                            .environmentObject(createWishlistViewModel)
                    case 1:
                        CreateWishlistPage2()
                            .environmentObject(createWishlistViewModel)
                    case 2:
                        CreateWishlistPage3()
                            .environmentObject(createWishlistViewModel)
                    default:
                        CreateWishlistPage1()
                            .environmentObject(createWishlistViewModel)
                    }
                    Spacer()
                }
                VStack {
                    Spacer()
                    WishieButton(
                        title: progressTabIndex < 2 ? "Next step" : "Create",
                        enabled: !createWishlistViewModel.name.isEmpty,
                        action: {
                            if (progressTabIndex < 2) {
                                progressTabIndex += 1
                            } else {
                                Task {
                                    creating = true
                                    do {
                                        let wishlist = try await createWishlistViewModel.saveItem()
                                        creating = false
                                        path.append(
                                            Route.createSuccess(
                                                wishListId: wishlist.id
                                            )
                                        )
                                    } catch {
                                        creating = false
                                        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                                    }
                                }
                            }
                        })
                    .padding(.bottom, 50)
                    .padding(.horizontal,20)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .showFullScreenDialog($creating)
    }
    @ViewBuilder
    func stepProgress() -> some View {
        HStack(spacing: 0) {
            circleStepItem(index: 0, step: "1")
                .onTapGesture {
                    progressTabIndex = 0
                }
            Rectangle()
                .fill(.black)
                .frame(width:70, height: 2)
            circleStepItem(index: 1, step: "2")
                .onTapGesture {
                    if ((progressTabIndex == 0 && !createWishlistViewModel.name.isEmpty) || progressTabIndex == 2) {
                        progressTabIndex = 1
                    }
                }
            Rectangle()
                .fill(.black)
                .frame(width: 70, height: 2)
            circleStepItem(index: 2, step: "3")
                .onTapGesture {
                    if ((progressTabIndex == 0 && !createWishlistViewModel.name.isEmpty) || progressTabIndex == 1) {
                        progressTabIndex = 2
                    }
                }
        }
    }
    @ViewBuilder
    func circleStepItem(index: Int,step: String) -> some View {
        Circle()
            .fill(index == progressTabIndex ? .wishiePink : .lightYellow)
            .frame(width: 50, height: 50)
            .overlay(content: {
                Text(step)
                    .font(.wishies(.regular, 15))
            })
    }
    
    @ViewBuilder
    func informationInputsPage1() -> some View {
        
    }
}
