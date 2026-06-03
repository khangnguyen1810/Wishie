# Share Context

## Important Instructions for Implementation

- Follow the existing MVVM pattern: one `ObservableObject` ViewModel per screen; all business logic, validation, and async operations belong in ViewModels, not Views.
- Email must remain read-only in the edit form; no changes to email sign-in credentials are in scope.
- Avatar images must be compressed to JPEG at `0.8` quality before upload, matching the established pattern in `WishlistService.upload(image:fileName:)`.
- The save button must be disabled (`enabled: !viewModel.isLoading`) and `.showFullScreenDialog($viewModel.isLoading)` active while any async save or upload is in-flight; never allow concurrent save submissions.
- Validate that `firstName` and `lastName` are non-empty after trimming whitespace before executing any network call; surface the violation via `EditProfileViewModel.errorMessage`.
- `avatarUrl` must default to `nil` on `UserModel` to preserve backward compatibility with all existing `UserModel` consumers such as `AuthViewModel.userInfo` and wishlist owner display.
- Firestore profile updates must use `updateData` (not `setData`) to preserve existing fields (`uid`, `email`, `createAt`) untouched.
- All new async service methods must be declared `async throws`; propagate errors to the ViewModel's `errorMessage` via `error.localizedDescription`.
- Do not introduce any code comments, debugging statements, or TODO markers.

## Reused Existing Functions/Utilities

- `WishlistService.upload(image:fileName:)`: Compresses a `UIImage` to JPEG 0.8 data, uploads to Supabase Storage bucket `"Wishie"`, returns the public URL string. Located in `Wishie/Services/WishlistService.swift`. The avatar upload implementation in `AuthenticateService` reuses this exact same pattern.
- `ImagePickerBox<Content: View>`: Reusable `PhotosPicker` wrapper; accepts `height: CGFloat`, `selectedImage: Binding<UIImage?>`, and a `@ViewBuilder content` closure. Binds the selected photo to `selectedImage`. Located in `Wishie/CustomView/ImagePickerBox.swift`. Used in `EditProfileView` to wrap the avatar circle.
- `DateInputView`: Reusable date-picker component; accepts `isCreating: Bool` and `date: Binding<Date>`. When `isCreating` is `false` the binding drives the displayed value directly. Located in `Wishie/CustomView/DateInputView.swift`. Used in `EditProfileView` for the `dateOfBirth` field with `isCreating: false`.
- `WishieButton(title:enabled:filColor:titleColor:action:)`: Primary button component. Located in `Wishie/CustomView/WishieButton.swift`. Used as the save button in `EditProfileView`.
- `BaseWishieScreen(topBar:content:)`: Root screen scaffold applying background color, safe-area ignoring, and `navigationBarBackButtonHidden()`. Located in `Wishie/Screens/BaseWishieScreen.swift`.
- `TopAppBar(leading:center:trailing:)`: Three-slot app bar builder (all slots default to `EmptyView`). Located in `Wishie/Screens/BaseWishieScreen.swift`. Used in both `ProfileView` (updated) and `EditProfileView` (new).
- `.showFullScreenDialog(_ isLoading: Binding<Bool>)`: View modifier that shows a full-screen loading overlay. Used in `EditProfileView` via `.showFullScreenDialog($viewModel.isLoading)`.
- `WishieConstants.userIdKey`: Static string constant `"userid"` for reading the authenticated user's UID from `UserDefaults`. Located in `Wishie/Constants/WishieConstants.swift`.
- `SupabaseManager.shared.client`: Singleton Supabase client used for storage operations. Located in `Wishie/Manager/SupabaseManager.swift`.
- `Date.toShortDateString()`: Formats a `Date` to `"dd MMM, yy"`. Located in `Wishie/Utils/DateExtension.swift`.

## Shared Contracts

### Entities

- `UserModel` (updated in Task 1.1): Represents an authenticated user's profile. Fields: `firstName: String` (default `""`), `lastName: String` (default `""`), `email: String` (default `""`), `phone: String` (default `""`), `password: String` (default `""`), `dateOfBirth: Date` (default `Date()`), `avatarUrl: String?` (new — default `nil`, mapped from Firestore key `"avatarUrl"`). Method `getFullName() -> String` returns trimmed concatenation. Struct conforms to `Codable` and `Hashable`.

### Interfaces

- `AuthenticateServiceProtocol` (updated in Task 1.2): Protocol for authentication and profile operations. Existing methods unchanged. Two new methods added for this feature:
  - `func uploadAvatar(image: UIImage, userId: String) async throws -> String` — uploads JPEG avatar to Supabase Storage path `"avatar/{userId}.jpg"` with upsert, returns public URL string.
  - `func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws` — writes updated profile fields to Firestore document `users/{userId}` using `updateData`.
  - Located in `Wishie/Services/AuthenticateService.swift`.

### DTOs

No new DTOs introduced. Profile update data is passed as individual named parameters to `updateUserInfo` matching the Firestore field schema established in `AuthenticateService.signUp`.

---

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

# Task 2: Add `editProfile` Navigation Route

- [ ] 2.1: In `Wishie/Models/Route.swift` UPDATE:
  - Add `case editProfile` to the `Route` enum.
  - No associated value is needed; `EditProfileView` (Task 4) receives its initial data through a `UserModel` parameter rather than the route.
  - `Route` already conforms to `Hashable`; no protocol conformance changes required.

# Task 3: Create `EditProfileViewModel`

- [ ] 3.1: In `Wishie/Screens/Profile/EditProfileViewModel.swift` CREATE:
  - Define `@MainActor class EditProfileViewModel: ObservableObject`.
  - `@Published` properties: `firstName: String = ""`, `lastName: String = ""`, `phone: String = ""`, `dateOfBirth: Date = Date()`, `selectedAvatar: UIImage? = nil`, `existingAvatarUrl: String? = nil`, `isLoading: Bool = false`, `errorMessage: String = ""`, `isSaveSuccess: Bool = false`.
  - `private let authService: AuthenticateServiceProtocol`.
  - `init(authService: AuthenticateServiceProtocol = AuthenticateService())` — assigns `self.authService = authService`.
  - `func populate(from user: UserModel)` — assigns `firstName = user.firstName`, `lastName = user.lastName`, `phone = user.phone`, `dateOfBirth = user.dateOfBirth`, `existingAvatarUrl = user.avatarUrl`.
  - Computed `var isValid: Bool` — returns `!firstName.trimmingCharacters(in: .whitespaces).isEmpty && !lastName.trimmingCharacters(in: .whitespaces).isEmpty`.
  - `func saveProfile() async`:
    - Guard `isValid`, else set `errorMessage = "First name and last name are required."` and `return`.
    - Guard `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)` as non-nil `userId`, else set `errorMessage = "User session not found."` and `return`.
    - Set `isLoading = true` and `errorMessage = ""`.
    - In `do`: if `selectedAvatar` is non-nil, `let avatarUrl = try await authService.uploadAvatar(image: selectedAvatar!, userId: userId)`, else `let avatarUrl = existingAvatarUrl`; then `try await authService.updateUserInfo(userId: userId, firstName: firstName, lastName: lastName, phone: phone, dateOfBirth: dateOfBirth, avatarUrl: avatarUrl)`; set `isLoading = false` and `isSaveSuccess = true`.
    - In `catch`: set `isLoading = false` and `errorMessage = error.localizedDescription`.

# Task 4: Create `EditProfileView`

- [ ] 4.1: In `Wishie/Screens/Profile/EditProfileView.swift` CREATE:
  - Define `struct EditProfileView: View` with `let userModel: UserModel` stored property, `@StateObject private var viewModel = EditProfileViewModel()`, and `@Environment(\.dismiss) private var dismiss`.
  - Use `BaseWishieScreen` as root:
    - `topBar`: `TopAppBar` with `leading` slot containing a `Circle().fill(.lightYellow).frame(width: 50, height: 50).overlay { Image("back_icon").resizable().scaledToFit().frame(width: 20) }.onTapGesture { dismiss() }` and `center` slot containing `Text("Edit Profile").font(.wishies(.bold, 20)).foregroundStyle(.black)`.
    - `content`: a `ScrollView` containing a `VStack(spacing: 24)` followed (outside the ScrollView) by a save button and padding.
  - Inside the `VStack(spacing: 24)` in the `ScrollView`:
    - **Avatar picker**: `ImagePickerBox(height: 100, selectedImage: $viewModel.selectedAvatar)` wrapping an avatar circle of 100×100. Display priority: (1) if `viewModel.selectedAvatar != nil`, show `Image(uiImage: viewModel.selectedAvatar!).resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())`; (2) else if `viewModel.existingAvatarUrl` is non-nil and non-empty, show `AsyncImage(url: URL(string: viewModel.existingAvatarUrl!))` with `.scaledToFill().frame(width: 100, height: 100).clipShape(Circle())` on success and a `Circle().fill(.lightYellow).frame(width: 100, height: 100)` placeholder; (3) else show `Circle().fill(.lightYellow).frame(width: 100, height: 100).overlay { Image("user").resizable().scaledToFit().frame(width: 50) }`.
    - **Error message**: `if !viewModel.errorMessage.isEmpty { Text(viewModel.errorMessage).font(.wishies(.regular, 15)).foregroundStyle(.wishiePink).multilineTextAlignment(.center).padding(.horizontal, 16) }`.
    - **Form fields** using the label-above-field pattern from `SignUpView`:
      - First name: `Text("First Name").font(.wishies(.bold, 17)).frame(maxWidth: .infinity, alignment: .leading)` + `TextField("First name", text: $viewModel.firstName).font(.wishies(.regular, 17)).padding(.horizontal, 15).textInputAutocapitalization(.never).background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }`.
      - Last name: same structure with `"Last Name"` / `"Last name"` label and `$viewModel.lastName`.
      - Phone: same structure with `"Phone"` / `"Phone"` label, `$viewModel.phone`, and `.keyboardType(.phonePad)`.
      - Email (read-only): `Text("Email").font(.wishies(.bold, 17)).frame(maxWidth: .infinity, alignment: .leading)` + `Text(userModel.email.isEmpty ? "-" : userModel.email).font(.wishies(.regular, 17)).padding(.horizontal, 15).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading).background { RoundedRectangle(cornerRadius: 15).fill(.lightGrey.opacity(0.4)) }`.
      - Date of Birth: `Text("Date of Birth").font(.wishies(.bold, 17)).frame(maxWidth: .infinity, alignment: .leading)` + `DateInputView(isCreating: false, date: $viewModel.dateOfBirth)`.
  - Below the `ScrollView` (still inside `BaseWishieScreen` content), place `WishieButton(title: "Save", enabled: !viewModel.isLoading, filColor: .wishiePink, titleColor: .black) { Task { await viewModel.saveProfile() } }.padding(.bottom, 20)`.
  - Apply `.showFullScreenDialog($viewModel.isLoading)` to the `BaseWishieScreen`.
  - Apply `.onAppear { viewModel.populate(from: userModel) }` to the `BaseWishieScreen`.
  - Apply `.onChange(of: viewModel.isSaveSuccess) { _, success in if success { dismiss() } }` to the `BaseWishieScreen`.

# Task 5: Update `ProfileView` — Avatar Display, Edit Navigation, and Post-Save Re-fetch

- [ ] 5.1: In `Wishie/Screens/Profile/ProfileView.swift` UPDATE:
  - Add `@State private var path = NavigationPath()` state property.
  - Wrap the entire existing `BaseWishieScreen { ... }` body inside `NavigationStack(path: $path) { ... }`.
  - In `TopAppBar`, add a `trailing:` slot with a `Circle().fill(.lightYellow).frame(width: 50, height: 50).overlay { Image("edit_icon").resizable().scaledToFit().frame(width: 20) }.onTapGesture { path.append(Route.editProfile) }`.
  - Replace the existing static placeholder avatar block (`Circle().fill(.lightYellow)...overlay { Image("user")... }`) with a conditional display: if `viewModel.userInfo.avatarUrl` is non-nil and non-empty, show `AsyncImage(url: URL(string: viewModel.userInfo.avatarUrl!))` — on `.success(let image)`: `image.resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())`; on `.failure` or `.empty`: the original `Circle().fill(.lightYellow).frame(width: 100, height: 100).overlay { Image("user").resizable().scaledToFit().frame(width: 50) }` placeholder. Preserve `.padding(.top, 20)`.
  - Add `.navigationDestination(for: Route.self) { route in switch route { case .editProfile: EditProfileView(userModel: viewModel.userInfo).onDisappear { Task { await viewModel.fetchUserInfo() } } default: EmptyView() } }` inside the `NavigationStack` body (after the `BaseWishieScreen` closing brace).
