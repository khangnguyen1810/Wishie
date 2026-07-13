//
//  EditWishlistInfoViewModel.swift
//  Wishie
//

import Foundation

@MainActor
class EditWishlistInfoViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var dueDate: Date = Date()
    @Published var selectedTheme: GradientTheme?
    @Published var isLoading: Bool = false
    @Published var didSave: Bool = false

    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    func load(wishlistId: String) async {
        do {
            isLoading = true
            let wishlist = try await service.getWishlist(by: wishlistId).0
            name = wishlist.name
            description = wishlist.description
            dueDate = wishlist.dueDate
            selectedTheme = wishlist.theme
            isLoading = false
        } catch {
            isLoading = false
            print(error)
        }
    }

    func save(wishlistId: String) async {
        do {
            isLoading = true
            let result = try await service.updateWishlistInfo(
                wishlistId: wishlistId,
                name: name,
                description: description,
                dueDate: dueDate,
                themeColor: selectedTheme?.rawValue
            )
            isLoading = false
            switch result {
            case .success:
                didSave = true
            case .failure(let error):
                print(error)
            }
        } catch {
            isLoading = false
            print(error)
        }
    }
}
