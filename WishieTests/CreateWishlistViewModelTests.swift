// WishieTests/CreateWishlistViewModelTests.swift
import Testing
import Foundation
@testable import Wishie

extension UserDefaultsSharingTests {
    @MainActor
    @Suite
    struct CreateWishlistViewModelTests {
        @Test func saveItemReturnsTheCreatedWishlistOnSuccess() async throws {
            UserDefaults.standard.set("u1", forKey: WishieConstants.userIdKey)
            defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
            let mockService = MockWishlistService()
            let created = WishlistModel(id: "w1", name: "Birthday", dueDate: Date(), userCreateId: "u1")
            mockService.createWishlistResult = .success(created)
            let viewModel = CreateWishlistViewModel(createWishListService: mockService)
            viewModel.name = "Birthday"

            let result = try await viewModel.saveItem()

            #expect(result.id == "w1")
            #expect(mockService.lastCreatedWishlist?.name == "Birthday")
        }

        @Test func saveItemThrowsWhenTheServiceFails() async throws {
            UserDefaults.standard.set("u1", forKey: WishieConstants.userIdKey)
            defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
            let mockService = MockWishlistService()
            mockService.createWishlistResult = .failure(APIError.transport("no network"))
            let viewModel = CreateWishlistViewModel(createWishListService: mockService)
            viewModel.name = "Birthday"

            do {
                _ = try await viewModel.saveItem()
                Issue.record("expected an error to be thrown")
            } catch let error as APIError {
                #expect(error == .transport("no network"))
            }
        }

        @Test func saveItemThrowsWhenNoUserIsLoggedIn() async throws {
            UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey)
            let mockService = MockWishlistService()
            let viewModel = CreateWishlistViewModel(createWishListService: mockService)
            viewModel.name = "Birthday"

            do {
                _ = try await viewModel.saveItem()
                Issue.record("expected an error to be thrown")
            } catch {
                #expect(mockService.lastCreatedWishlist == nil)
            }
        }
    }
}
