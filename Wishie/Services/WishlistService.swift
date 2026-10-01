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
    func createWishlist(wishList: WishlistModel) async throws -> WishlistModel
    func upload(wishlistId: String, image: UIImage) async throws -> String
    func getWishlist(by id: String) async throws -> Result<WishlistModel, WishieError>
    /// Not `throws`: the implementation funnels every failure into `.failure`, so a `throws` here
    /// would only force callers to write `catch` blocks that can never run.
    func getWishlistInfoByCode(by code: String) async -> Result<WishlistInfoResponse, WishieError>
    /// `code` is the invite code from `GET /wishlists/:id/share`, carried in the QR link —
    /// `POST /wishlists/join/:code` does not accept a wishlist UUID. Returns the joined
    /// wishlist's id.
    func joinWishlist(code: String) async -> Result<String, WishieError>
    /// Owner-only. Returns the wishlist's current invite code, minting one server-side on first
    /// call. Idempotent — safe to call every time the owner opens the share screen.
    func getInviteCode(wishlistId: String) async -> Result<String, WishieError>
    func getUserWishlists() async throws -> [WishlistModel]
    func getProfile(id: String) async throws -> UserModel
    func pickItem(wishlistId: String, itemId: String) async throws -> Result<WishlistItem, WishieError>
    func updateWishlistItem(wishlistId: String,itemId: String,newName: String?,newDescription: String?,newImage: UIImage?,newImageLink: String?,newPrice: String?, newLink: String?) async throws -> Result<WishlistItem, WishieError>
    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, WishieError>
    func updateWishlistInfo(wishlistId: String, name: String, description: String, dueDate: Date, themeColor: String?) async throws -> Result<WishlistResponse, WishieError>
    /// The returned model comes from `PATCH /wishlists/:id/archive`, whose response omits
    /// `members` and `items` — so `members`, `items`, `memberProfiles` and `ownerName` are
    /// empty. Re-fetch the list rather than swapping this model into it.
    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<WishlistModel, WishieError>
    func leaveWishlist(wishListId: String) async throws -> Result<Bool, WishieError>
    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, WishieError>
    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<WishlistItemResponse, WishieError>
    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, WishieError>
    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> ListenerRegistration?
}

extension WishlistServiceProtocol {
    /// Resolves each wishlist's owner profile, deduped per distinct `userCreateId` and fetched
    /// concurrently — shared by `HomeViewModel` and `ArchivedWishlistsViewModel` so owner-profile
    /// resolution isn't duplicated per screen.
    ///
    /// Individual `getProfile` failures (e.g. a 404 or timeout for one friend's profile) are
    /// swallowed rather than propagated, and fall back to a `UserModel` built from the wishlist's
    /// own `ownerName` (already included in `WishlistResponse`) so a bad/unavailable profile
    /// fetch never drops the wishlist itself from the result — only the richer profile fields
    /// (avatar, email, etc.) are missing for that entry.
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
        return wishlists.map { wishlist in
            let profile = profilesByOwnerId[wishlist.userCreateId]
                ?? UserModel(dictionary: ["firstName": wishlist.ownerName ?? ""])
            return (wishlist, profile)
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

    func createWishlist(wishList: WishlistModel) async throws -> WishlistModel {
        let response: WishlistResponse = try await apiService.send(.createWishlist(CreateWishlistRequest(wishList)))
        let model = WishlistModel(response: response)

        await withTaskGroup(of: Void.self) { group in
            for item in wishList.items where item.localImage != nil {
                group.addTask {
                    do {
                        try await self.uploadItemImage(wishlistId: model.id, itemId: item.id, image: item.localImage!)
                    } catch {
                        print("WishlistService.createWishlist: image upload failed for item \(item.id): \(error)")
                    }
                }
            }
        }

        return model
    }
    
    func updateWishlistItem(
        wishlistId: String,
        itemId: String,
        newName: String?,
        newDescription: String?,
        newImage: UIImage?,
        newImageLink: String?,
        newPrice: String?,
        newLink: String?
    ) async throws -> Result<WishlistItem, WishieError> {
        do {
            let response: WishlistItemResponse = try await apiService
                .send(.editWishlistItem(
                    wishlistId: wishlistId,
                    itemId: itemId,
                    wishItem: EditWishlistItemRequest(
                        name: newName,
                        description: newDescription,
                        price: newPrice,
                        link: newLink,
                        imageLink: newImageLink
                    )
                ))
            var model = WishlistItem(response: response)
            if let newImage {
                model.image = try await self.uploadItemImage(wishlistId: wishlistId, itemId: itemId, image: newImage)
            }
           
            return .success(model)
        } catch {
            return .failure(WishieError(error))
        }
    }

    /// Best-effort — a failed upload here doesn't fail `createWishlist`, since the wishlist and
    /// its items already exist server-side by the time this runs. Mirrors the swallow-per-item
    /// convention in `WishlistServiceProtocol.pairWithOwnerProfiles` above.
    @discardableResult
    private func uploadItemImage(wishlistId: String, itemId: String, image: UIImage) async throws -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let response: WishlistItemResponse = try await apiService.send(.uploadItemImage(wishlistId: wishlistId, itemId: itemId, imageData: data))
        return response.imageUrl
    }

    /// Uploads through the backend's service-role Supabase client rather than talking to Supabase
    /// Storage directly from the app — direct client uploads run as the `authenticated` Postgres
    /// role, and `storage.objects` RLS on the "Wishie" bucket only grants `anon`, so they were
    /// failing with "new row violates row-level security policy" for every logged-in user.
    func upload(
        wishlistId: String,
        image: UIImage
    ) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "image", code: -1)
        }
        let response: WishlistImageUploadResponse = try await apiService.send(
            .uploadWishlistImage(wishlistId: wishlistId, imageData: data)
        )
        return response.imageUrl
    }
    func getWishlist(by id: String) async throws -> Result<WishlistModel, WishieError> {
        do {
            let response: WishlistResponse = try await apiService.send(.getDetailWishlist(wishlistId: id))
            let model = WishlistModel(response: response)
            return .success(model)
        } catch {
            return .failure(WishieError(error))
        }
    }
    func joinWishlist(code: String) async -> Result<String, WishieError> {
        do {
            let response: JoinWishlistResponse = try await apiService.send(.joinWishlist(code: code))
            // A 200 carrying `success: false` would otherwise be reported to the user as a
            // successful join and navigate them into a wishlist they aren't a member of.
            guard response.success else {
                return .failure(WishieError.invalidResponse)
            }
            return .success(response.wishlistId)
        } catch {
            return .failure(WishieError(error))
        }
    }

    func getInviteCode(wishlistId: String) async -> Result<String, WishieError> {
        do {
            let response: InviteCodeResponse = try await apiService.send(.getInviteCode(wishlistId: wishlistId))
            return .success(response.inviteCode)
        } catch {
            return .failure(WishieError(error))
        }
    }
    func pickItem(wishlistId: String, itemId: String) async throws -> Result<WishlistItem, WishieError> {
        do {
            let response: WishlistItemResponse = try await apiService.send(.pickItem(wishlistId: wishlistId, itemId: itemId))
            let model = WishlistItem(response: response)
            return .success(model)
        } catch {
            return .failure(WishieError(error))
        }
    }
    
    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, WishieError> {
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
            return .failure(WishieError(error))
        }
    }

    func updateWishlistInfo(
        wishlistId: String,
        name: String,
        description: String,
        dueDate: Date,
        themeColor: String?
    ) async throws -> Result<WishlistResponse, WishieError> {
        do {
            let request = EditWishlistRequest(
                name: name,
                description: description,
                dueDate: WishieDateFormatting.dateOnly.string(from: dueDate),
                colorTheme: themeColor)
            let response: WishlistResponse = try await apiService.send(.editWishlist(wishlistId: wishlistId, wishlist: request))
            return .success(response)
        } catch {
            return .failure(WishieError(error))
        }
    }

    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<WishlistModel, WishieError> {
        do {
            let response: WishlistResponse = try await apiService.send(.archiveWishlist(wishlistId: wishlistId, isArchived: isArchived))
            let model = WishlistModel(response: response)
            return .success(model)
        } catch {
            return .failure(WishieError(error))
        }
    }

    func leaveWishlist(wishListId: String) async throws -> Result<Bool, WishieError> {
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
            return .failure(WishieError(error))
        }
    }
    
    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, WishieError> {
        do {
            let response: DeleteResponse = try await apiService.send(.deleteItem(wishlistId: wishlistId, itemId: itemId))
            guard response.success else {
                return .failure(WishieError.invalidResponse)
            }
            return .success(true)
        } catch {
            return .failure(WishieError(error))
        }
    }

    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<WishlistItemResponse, WishieError> {
        do {
            let response: WishlistItemResponse = try await apiService.send(
                .markItemDesired(
                    wishlistId: wishlistId,
                    itemId: itemId,
                    isMostDesired: isMostDesired)
            )
            return .success(response)
        } catch {
            return .failure(WishieError(error))
        }
    }

    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, WishieError> {
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
            return .failure(WishieError(error))
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
    func getWishlistInfoByCode(by code: String) async -> Result<WishlistInfoResponse, WishieError> {
        do {
            let response: WishlistInfoResponse = try await apiService.send(.getWishlistInfoByCode(code: code))
            return .success(response)
        } catch {
            return .failure(WishieError(error))
        }
    }
}
