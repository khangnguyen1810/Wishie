//
//  HomeViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 9/2/26.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var myWishlists: [(WishlistModel, UserModel)] = []
    @Published var myFriendWishlists: [(WishlistModel, UserModel)] = []
    @Published var isGettingList: Bool = false
    @Published var errorMessage: String = ""
    private var service: WishlistServiceProtocol
    
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }
    
    func getListWishlist() async {
        do {
            isGettingList = true
            let result = try await service.getUserWishlists()
            switch result {
            case .success(let list):
                isGettingList = false
                guard let userId = UserDefaults.standard.string(forKey: "userid") else { return }
                   
                   self.myWishlists = list.filter {
                       $0.0.members[userId] == .owner
                   }
                   
                   self.myFriendWishlists = list.filter {
                       $0.0.members[userId] == .member
                   }
            case .failure(let error):
                isGettingList = false
                self.errorMessage = error.localizedDescription
            }
        } catch {
            isGettingList = false
            self.errorMessage = error.localizedDescription
        }
    }
    func deleteWishlist(wishlistId: String) async {
        do {
            let result = try await service.deleteWishlist(wishlistId:  wishlistId)
            switch result {
            case .success(let success):
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    func leaveWishlist(wishlistId: String) async {
        do {
            let result = try await service.leaveWishlist(wishListId:  wishlistId)
            switch result {
            case .success(let success):
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
