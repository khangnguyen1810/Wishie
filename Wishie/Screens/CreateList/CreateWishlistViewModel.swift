//
//  CreateWishlistViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import Foundation
import UIKit

class CreateWishlistViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var dueDate: Date = Date()
    @Published var items: [WishlistItem] = []
    @Published var selectedTheme: GradientTheme?
    private var createWishListService: WishlistServiceProtocol
    
    init (createWishListService: WishlistServiceProtocol = WishlistService()) {
        self.createWishListService = createWishListService
    }
    func saveItem() async -> Result<String, Error>{
        do {
            guard let userId = UserDefaults.standard.string(forKey: "userid") else {
                return .failure(NSError(
                    domain: "UserError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
                ))
            }
            for index in items.indices {
                guard let image = items[index].localImage else { continue }
                let imageUrl = try await createWishListService.upload(image: image, fileName: UUID().uuidString)
                items[index].image = imageUrl
                items[index].localImage = nil
            }
            let wishList =  WishlistModel(
                name: name,
                description: description,
                dueDate: dueDate,
                items: items,
                themeColor: selectedTheme?.rawValue,
                userCreateId: userId)
            return try await createWishListService.createWishlist(wishList: wishList)
        } catch {
            return .failure(error)
        }
    }
}

