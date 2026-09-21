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
    @Published var wishlistInfo: WishlistModel = WishlistModel(name: "", userCreateId: "", ownerName: "")
    @Published var isLoading: Bool = false
   
    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }
    func getWishlistInfo(wishListId: String) async {
        do {
            isLoading = true
            let result = try await service.getWishlist(by: wishListId)
            switch result {
            case .success(let success):
                wishlistInfo = success
            case .failure(let failure):
                print(failure.localizedDescription)
            }
            isLoading = false
        } catch {
            isLoading = false
            print(error)
        }
    }
}
