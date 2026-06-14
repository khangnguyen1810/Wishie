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
    func getWishlist(by id: String) async throws -> (WishlistModel, UserModel)
    func joinWishlist(wishListId: String) async throws  -> Result<Bool, Error>
    func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], Error>
    func pickItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>
    func updateWishlistItem(wishlistId: String, itemId: String, newName: String?, newDescription: String?, newImage: UIImage?) async throws -> Result<Bool, Error>
    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, Error>
    func leaveWishlist(wishListId: String) async throws -> Result<Bool, Error>
    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>
    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, Error>
    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error>
    func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void, onError: @escaping (Error) -> Void) -> ListenerRegistration
    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> ListenerRegistration?
}

class WishlistService: WishlistServiceProtocol {
    private let db = Firestore.firestore()
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error> {
        do {
            let data : [String: Any] = [
                "id": wishList.id,
                "wishListName": wishList.name,
                "description": wishList.description,
                "userCreateId": wishList.userCreateId,
                "dueDate": Timestamp(date: wishList.dueDate),
                "colorTheme": wishList.themeColor ?? "",
                "wishListItems": wishList.items.map {
                    [
                        "id": $0.id,
                        "name": $0.name,
                        "description": $0.description,
                        "imageUrl": $0.image ?? "",
                        "isPicked": $0.isPicked,
                        "itemLink": $0.itemLink,
                        "price": $0.price ?? ""
                    ]
                },
                "members": [
                    wishList.userCreateId: "owner"
                ]
            ]
            try await db
                .collection("wishList")
                .document(wishList.id)
                .setData(data)
            
            let userWishlistData: [String: Any] = [
                "role": "owner",
                "joinedAt": Timestamp()
            ]
            
            try await db
                .collection("users")
                .document(wishList.userCreateId)
                .collection("wishlists")
                .document(wishList.id)
                .setData(userWishlistData)
            
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
    func getWishlist(by id: String) async throws -> (WishlistModel, UserModel) {
        
        let snapshot = try await db
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
        
        let wishlist = try WishlistModel(dictionary: data)
        let ownerSnapshot = try await db.collection(
            WishieConstants.firebaseUserPath
        ).document(wishlist.userCreateId).getDocument()
        guard let userData = ownerSnapshot.data() else {
            throw NSError(
                domain: "WishlistService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User not found"]
            )
        }
        let owner = UserModel(dictionary: userData)
        return (wishlist, owner)
    }
    func joinWishlist(wishListId: String) async throws -> Result<Bool, any Error> {
        do {
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            
            let batch = db.batch()
            
            let wishListDoc = db
                .collection("wishList")
                .document(wishListId)
            
            let userDoc = db
                .collection("users")
                .document(userId)
                .collection("wishlists")
                .document(wishListId)
            
            let userWishlistData: [String: Any] = [
                "role": "member",
                "joinedAt": Timestamp()
            ]
            
            batch.updateData([
                "members.\(userId)": "member"
            ], forDocument: wishListDoc)
            
            batch.setData(userWishlistData, forDocument: userDoc)
            
            try await batch.commit()
            
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], any Error> {
        do {
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                throw NSError(domain: "WishlistServie", code: 404)
            }
            let snapshot = try await db
                .collection(WishieConstants.firebaseUserPath)
                .document(userId)
                .collection(WishieConstants.firebaseWishlistPath)
                .order(by: "joinedAt")
                .getDocuments()
            let wishlistIds = snapshot.documents.map { $0.documentID }
            
            let wishlists = try await withThrowingTaskGroup(of: (WishlistModel, UserModel).self) { [weak self] group in
                guard let self else { throw NSError(domain: "", code: 404) }
                for id in wishlistIds {
                    group.addTask {
                        let wishlist = try await self.getWishlist(by: id)
                        return (wishlist.0, wishlist.1)
                    }
                }
                
                var results: [(WishlistModel, UserModel)] = []
                
                for try await result in group {
                    results.append(result)
                }
                
                return results
            }
            return .success(wishlists)
        } catch {
            return .failure(error)
        }
    }
    func pickItem(wishlistId: String, itemId: String) async throws -> Result<Bool, any Error> {
        do {
            guard let userId = UserDefaults.standard.string(
                forKey: WishieConstants.userIdKey
            ) else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            let docRef = db.collection("wishList").document(wishlistId)
            let snapshot = try await docRef.getDocument()
            guard let data = snapshot.data(),
                  var items = data["wishListItems"] as? [[String: Any]] else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            for index in items.indices {
                if let id = items[index]["id"] as? String, id == itemId {
                    items[index]["isPicked"] = true
                    items[index]["pickedBy"] = userId
                    break
                }
            }
            
            try await docRef.updateData([
                "wishListItems": items
            ])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    func updateWishlistItem(
        wishlistId: String,
        itemId: String,
        newName: String?,
        newDescription: String?,
        newImage: UIImage?
    ) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList")
                .document(wishlistId)
            let snapshot = try await docRef.getDocument()
            guard var items: [[String: Any]] = snapshot.data()?["wishListItems"] as? [[String: Any]] else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            for index in items.indices {
                if let id = items[index]["id"] as? String, id == itemId {
                    if let newName {
                        items[index]["name"] = newName
                    }
                    if let newDescription {
                        items[index]["description"] = newDescription
                    }
                    if let newImage {
                       
                        if let oldUrl = items[index]["imageUrl"] as? String,
                           !oldUrl.isEmpty {
                            try? await deleteImageStorage(imageUrl: oldUrl)
                        }
                        
                        let fileName = UUID().uuidString
                        let newUrl = try await upload(image: newImage, fileName: fileName)
                        items[index]["imageUrl"] = newUrl
                    }
                    break
                }
            }
            try await docRef.updateData([
                "wishListItems": items
            ])
            
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList").document(wishlistId)
            let snapshot = try await docRef.getDocument()
            guard let data = snapshot.data(),
                  let members = data["members"] as? [String: String],
                  let items = data["wishListItems"] as? [[String: Any]] else {
                throw NSError(domain: "Wishlist Service", code: 404)
            }
            for item in items {
                if let url = item["imageUrl"] as? String, !url.isEmpty {
                    try await deleteImageStorage(imageUrl: url)
                }
            }
            let batch = db.batch()
            batch.deleteDocument(docRef)
            for (userId, _) in members {
                let userRef = db
                    .collection("users")
                    .document(userId)
                    .collection("wishlists")
                    .document(wishlistId)
                batch.deleteDocument(userRef)
            }
            try await batch.commit()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func leaveWishlist(wishListId: String) async throws -> Result<Bool, any Error> {
        do {
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                throw NSError(domain: "Wishie App Storage", code: 403)
            }
            let docRef = db.collection("wishList").document(wishListId)
            let snapshot = try await docRef.getDocument()
            guard let data = snapshot.data(),
                  var items = data["wishListItems"] as? [[String: Any]] else {
                throw NSError(domain: "Wishlist Service", code: 404)
            }
            for index in items.indices {
                if let pickedBy = items[index]["pickedBy"] as? String, pickedBy == userId {
                    items[index]["pickedBy"] = nil
                    items[index]["isPicked"] = false
                }
            }
            let batch = db.batch()
            batch.updateData([
                "members.\(userId)": FieldValue.delete(),
                "wishListItems": items
            ], forDocument: docRef)
            let userRef = db.collection("users")
                .document(userId)
                .collection("wishlists")
                .document(wishListId)
            batch.deleteDocument(userRef)
            try await batch.commit()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList").document(wishlistId)
            let snapshot = try await docRef.getDocument()
            guard let data = snapshot.data(),
                  let items = data["wishListItems"] as? [[String: Any]] else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            let filteredItems = items.filter { ($0["id"] as? String) != itemId }
            try await docRef.updateData(["wishListItems": filteredItems])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList").document(wishlistId)
            let snapshot = try await docRef.getDocument()
            guard var items = snapshot.data()?["wishListItems"] as? [[String: Any]] else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            for index in items.indices {
                if let id = items[index]["id"] as? String, id == itemId {
                    items[index]["isMostDesired"] = isMostDesired
                    break
                }
            }
            try await docRef.updateData(["wishListItems": items])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error> {
        do {
            let itemData: [String: Any] = [
                "id": item.id,
                "name": item.name,
                "description": item.description,
                "imageUrl": item.image ?? "",
                "isPicked": item.isPicked,
                "itemLink": item.itemLink,
                "price": item.price ?? "",
                "isMostDesired": item.isMostDesired
            ]
            let docRef = db.collection("wishList").document(wishlistId)
            try await docRef.updateData([
                "wishListItems": FieldValue.arrayUnion([itemData])
            ])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void, onError: @escaping (Error) -> Void) -> ListenerRegistration {
        return db.collection("wishList").document(id).addSnapshotListener { snapshot, error in
            if let error = error {
                onError(error)
                return
            }
            guard let data = snapshot?.data(),
                  let wishlist = try? WishlistModel(dictionary: data) else { return }
            onChange(wishlist)
        }
    }

    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> ListenerRegistration? {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            return nil
        }
        return db
            .collection(WishieConstants.firebaseUserPath)
            .document(userId)
            .collection(WishieConstants.firebaseWishlistPath)
            .order(by: "joinedAt")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                onChange(documents.map { $0.documentID })
            }
    }

    private func deleteImageStorage(imageUrl: String) async throws {
        guard let range = imageUrl.range(
            of: "/storage/v1/object/public/Wishie/"
        ) else  { return }
        let path = String(imageUrl[range.upperBound...])
        
        try await SupabaseManager.shared.client
            .storage
            .from("Wishie")
            .remove(paths: [path])
    }
}
