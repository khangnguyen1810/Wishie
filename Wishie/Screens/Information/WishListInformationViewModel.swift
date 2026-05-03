//
//  WishListInformationViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//

import Foundation
import FirebaseFirestore

@MainActor
class WishListInformationViewModel: ObservableObject {
    @Published var wishlistInfo: WishlistModel = WishlistModel(name: "", userCreateId: "")
    @Published var ownerInfo: UserModel = UserModel()
    @Published var isLoading: Bool = false
   
    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }
    func getWishlistInfo(wishListId: String) async {
        do {
            isLoading = true
            wishlistInfo = try await service.getWishlist(by: wishListId).0
            ownerInfo = try await service.getWishlist(by: wishListId).1
            isLoading = false
        } catch {
            isLoading = false
            print(error)
        }
    }
}
