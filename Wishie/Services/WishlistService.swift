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
    func getUserWishlists() async throws -> [WishlistModel]
    func getProfile(id: String) async throws -> UserModel
    func pickItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>
    func updateWishlistItem(wishlistId: String, itemId: String, newName: String?, newDescription: String?, newImage: UIImage?, newPrice: String?) async throws -> Result<Bool, Error>
    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, Error>
    func updateWishlistInfo(wishlistId: String, name: String, description: String, dueDate: Date, themeColor: String?) async throws -> Result<Bool, Error>
    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, Error>
    func leaveWishlist(wishListId: String) async throws -> Result<Bool, Error>
    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>
    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, Error>
    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error>
    func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void, onError: @escaping (Error) -> Void) -> ListenerRegistration
    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> ListenerRegistration?
}

extension WishlistServiceProtocol {
    /// Resolves each wishlist's owner profile, deduped per distinct `userCreateId` and fetched
    /// concurrently — shared by `HomeViewModel` and `ArchivedWishlistsViewModel` so owner-profile
    /// resolution isn't duplicated per screen.
    ///
    /// Individual `getProfile` failures (e.g. a 404 or timeout for one friend's profile) are
    /// swallowed rather than propagated, so one bad profile only drops that one wishlist from the
    /// result instead of failing the whole screen — see `HomeViewModel.getListWishlist()`, which
    /// awaits both the owned and joined calls together.
    func pairWithOwnerProfiles(_ wishlists: [WishlistModel]) async -> [(WishlistModel, UserModel)] {
        let ownerIds = Set(wishlists.map(\.userCreateId))
        let profilesByOwnerId = await withTaskGroup(of: (String, UserModel?).self) { group in
            for ownerId in ownerIds {
                group.addTask { (ownerId, try? await self.getProfile(id: ownerId)) }
            }
            var result: [String: UserModel] = [:]
            for await (ownerId, profile) in group {
                if let profile { result[ownerId] = profile }
            }
            return result
        }
        return wishlists.compactMap { wishlist in
            profilesByOwnerId[wishlist.userCreateId].map { (wishlist, $0) }
        }
    }
}

class WishlistService: WishlistServiceProtocol {
    private let db = Firestore.firestore()
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    func getUserWishlists() async throws -> [WishlistModel] {
        let responses: [WishlistResponse] = try await apiService.send(.getWishlists)
        return responses.map(WishlistModel.init(response:))
    }

    func getProfile(id: String) async throws -> UserModel {
        let response: ProfileResponse = try await apiService.send(.getProfile(id: id))
        return UserModel(profile: response)
    }

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
        newImage: UIImage?,
        newPrice: String?
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
                    if let newPrice {
                        items[index]["price"] = newPrice
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

    func updateWishlistInfo(
        wishlistId: String,
        name: String,
        description: String,
        dueDate: Date,
        themeColor: String?
    ) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList").document(wishlistId)
            try await docRef.updateData([
                "wishListName": name,
                "description": description,
                "dueDate": Timestamp(date: dueDate),
                "colorTheme": themeColor ?? ""
            ])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList").document(wishlistId)
            try await docRef.updateData([
                "isArchived": isArchived
            ])
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
            guard let items = snapshot.data()?["wishListItems"] as? [[String: Any]] else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            let updatedItems = MostDesiredRule.apply(
                items: items,
                itemId: itemId,
                isMostDesired: isMostDesired
            )
            try await docRef.updateData(["wishListItems": updatedItems])
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
