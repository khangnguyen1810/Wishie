//
//  CreateWishlistService.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 17/12/25.
//

import Foundation
import FirebaseFirestore
import Supabase

protocol WishlistServiceProtocol {
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error>
    func upload(image: UIImage, fileName: String) async throws -> String
    func getWishlist(by id: String, of ownerId: String) async throws -> WishlistModel
}

class WishlistService: WishlistServiceProtocol {
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error> {
        do {
            let data : [String: Any] = [
                "id": wishList.id,
                "wishListName": wishList.name,
                "description": wishList.description,
                "userCreateId": wishList.userCreateId,
                "dueDate": wishList.dueDate,
                "colorTheme": wishList.themeColor ?? "",
                "wishListItems": wishList.items.map {
                    [
                        "id": $0.id,
                        "name": $0.name,
                        "description": $0.description,
                        "imageUrl": $0.image ?? "",
                        "isPicked": $0.isPicked
                    ]
                }
            ]
            try await Firestore.firestore()
                .collection("users")
                .document(wishList.userCreateId)
                .collection("wishList")
                .document(wishList.id)
                .setData(data)
            return .success(wishList.id)
        } catch {
            return .failure(error)
        }
    }
    func upload(
        image: UIImage,
        fileName: String
    ) async throws -> String {
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "image", code: -1)
        }
        
        let path = "wishlist/\(fileName).jpg"
        
        try await SupabaseManager.shared.client
            .storage
            .from("Wishie")
            .upload(
                path,
                data: data,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        let url = try SupabaseManager.shared.client
            .storage
            .from("Wishie")
            .getPublicURL(path: path)
        
        return url.absoluteString
    }
    func getWishlist(by id: String, of ownerId: String) async throws -> WishlistModel {
      
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(ownerId)
            .collection("wishList")
            .document(id)
            .getDocument()
        
        guard let data = snapshot.data() else {
            throw NSError(
                domain: "WishlistService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Wishlist not found"]
            )
        }
        
        return try WishlistModel(dictionary: data)
    }
}
