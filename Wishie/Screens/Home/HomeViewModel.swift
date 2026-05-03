//
//  HomeViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 9/2/26.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var wishlists: [WishlistModel] = []
    @Published var isGettingList: Bool = false
    private var service: WishlistServiceProtocol
    
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }
    
    func getListWishlist() {
        
    }
}
