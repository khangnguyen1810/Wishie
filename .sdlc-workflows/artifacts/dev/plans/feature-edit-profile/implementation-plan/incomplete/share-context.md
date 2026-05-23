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

