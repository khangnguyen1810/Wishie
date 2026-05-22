# Task 1: Update Data Layer — `UserModel`, `AuthenticateServiceProtocol`, and `AuthenticateService`

- [ ] 1.1: In `Wishie/Models/UserModel.swift` UPDATE:
  - Add `var avatarUrl: String? = nil` property to `UserModel` after the existing `dateOfBirth` property.
  - In `init(dictionary: [String: Any])`, add `self.avatarUrl = dictionary["avatarUrl"] as? String` after the `dateOfBirth` mapping block.
  - No changes to `getFullName()` or any other existing property; backward compatibility is maintained because `avatarUrl` defaults to `nil`.

- [ ] 1.2: In `Wishie/Services/AuthenticateService.swift` UPDATE `AuthenticateServiceProtocol`:
  - Add `import UIKit` at the top of the file (needed for `UIImage` in the new protocol methods).
  - Add `func uploadAvatar(image: UIImage, userId: String) async throws -> String` to the protocol body.
  - Add `func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws` to the protocol body.

- [ ] 1.3: In `Wishie/Services/AuthenticateService.swift` UPDATE `AuthenticateService` class body:
  - Implement `uploadAvatar(image:userId:)`:
    - Guard `image.jpegData(compressionQuality: 0.8)` to obtain `data`; if nil throw `NSError(domain: "avatar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."])`.
    - Set `let path = "avatar/\(userId).jpg"`.
    - `try await SupabaseManager.shared.client.storage.from("Wishie").upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))`.
    - Return `try SupabaseManager.shared.client.storage.from("Wishie").getPublicURL(path: path).absoluteString`.
  - Implement `updateUserInfo(userId:firstName:lastName:phone:dateOfBirth:avatarUrl:)`:
    - Build `var updateDict: [String: Any] = ["firstName": firstName, "lastName": lastName, "phone": phone, "dateOfBirth": Timestamp(date: dateOfBirth)]`.
    - If `avatarUrl` is non-nil, set `updateDict["avatarUrl"] = avatarUrl!`.
    - `try await db.collection("users").document(userId).updateData(updateDict)`.

