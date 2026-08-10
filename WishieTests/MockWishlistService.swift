//
//  MockWishlistService.swift
//  WishieTests
//

import Foundation
import UIKit
import FirebaseFirestore
@testable import Wishie

/// Minimal `ListenerRegistration` stand-in so `MockWishlistService` can satisfy
/// the protocol without touching real Firestore.
final class FakeListenerRegistration: NSObject, ListenerRegistration {
    func remove() {}
}

final class MockWishlistService: WishlistServiceProtocol {
    // MARK: - upload
    var uploadResult: Result<String, Error> = .success("https://uploaded.example.com/img.jpg")
    private(set) var uploadCallCount = 0
    private(set) var lastUploadedImage: UIImage?
    private(set) var lastUploadFileName: String?

    func upload(image: UIImage, fileName: String) async throws -> String {
        uploadCallCount += 1
        lastUploadedImage = image
        lastUploadFileName = fileName
        return try uploadResult.get()
    }

    // MARK: - addWishlistItem
    var addWishlistItemResult: Result<Bool, Error> = .success(true)
    private(set) var addedItems: [WishlistItem] = []

    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error> {
        addedItems.append(item)
        return addWishlistItemResult
    }

    // MARK: - Unused by these tests; minimal stub bodies.
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error> {
        .success(wishList.id)
    }

    func getWishlist(by id: String) async throws -> (WishlistModel, UserModel) {
        (WishlistModel(name: "", userCreateId: ""), UserModel())
    }

    func joinWishlist(wishListId: String) async throws -> Result<Bool, Error> {
        .success(true)
    }

    var wishlistsResult: Result<[WishlistModel], Error> = .success([])
    func getUserWishlists() async throws -> [WishlistModel] {
        try wishlistsResult.get()
    }

    var profilesById: [String: UserModel] = [:]
    var getProfileError: Error?
    private(set) var requestedProfileIds: [String] = []
    func getProfile(id: String) async throws -> UserModel {
        requestedProfileIds.append(id)
        if let getProfileError { throw getProfileError }
        return profilesById[id] ?? UserModel()
    }

    func pickItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func updateWishlistItem(wishlistId: String, itemId: String, newName: String?, newDescription: String?, newImage: UIImage?, newPrice: String?) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func updateWishlistInfo(wishlistId: String, name: String, description: String, dueDate: Date, themeColor: String?) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func leaveWishlist(wishListId: String) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, Error> {
        .success(true)
    }

    func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void, onError: @escaping (Error) -> Void) -> ListenerRegistration {
        FakeListenerRegistration()
    }

    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> ListenerRegistration? {
        nil
    }
}
