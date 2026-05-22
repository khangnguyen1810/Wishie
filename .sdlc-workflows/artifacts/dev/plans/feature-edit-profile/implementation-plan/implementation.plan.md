Edit Profile Info and Upload Avatar

# Requirement Context

## Current State

`ProfileView` displays user profile info (Full Name, Date of Birth, Email, Phone) in a read-only row list. No edit capability exists. `UserModel` has no `avatarUrl` field. `AuthenticateService` has no update method. `WishlistService` already contains a working `upload(image:fileName:)` method using Supabase Storage (bucket: `Wishie`). `ImagePickerBox` is a reusable `PhotosPicker` wrapper available in `CustomView`.

## Goals

- Allow authenticated users to edit their profile information (firstName, lastName, phone, dateOfBirth).
- Allow users to upload or replace their avatar photo, stored in Supabase Storage with the URL persisted in Firestore.
- Reflect updated profile data immediately in `ProfileView` after a successful save.

## Risk & Mitigation

- **Email change requires Firebase Auth re-authentication**: changing email is a sensitive operation that demands credential re-entry and introduces an additional authentication flow. Mitigation: treat email as read-only in the edit form (pending clarification).
- **Large images degrading upload performance**: Mitigation: compress images to JPEG at 0.8 quality before upload, consistent with the existing `WishlistService.upload` pattern.
- **Concurrent save while upload is in-flight**: Mitigation: disable the save button and show a loading overlay until both the upload and Firestore write complete.

# Technical Specification Context

## Functional Requirements:

- System MUST allow users to edit `firstName`, `lastName`, `phone`, and `dateOfBirth` fields.
- System MUST allow users to select a new avatar image from the device photo library using `PhotosPicker`.
- System MUST upload the selected avatar image to Supabase Storage under the path `avatar/{userId}.jpg` with `upsert: true`.
- System MUST persist the returned public avatar URL alongside updated profile fields in the Firestore `users/{userId}` document.
- System MUST display the current avatar in `ProfileView`, falling back to the existing placeholder when no URL is present.
- System MUST validate that `firstName` and `lastName` are not empty before allowing save.
- System MUST surface a localised error message via `ProfileViewModel.errorMessage` when any save or upload operation fails.
- System MUST show the existing loading overlay (`showFullScreenDialog`) while a save operation is in progress.
- System MUST re-fetch and reflect updated user info in `ProfileView` after a successful save.
- System MUST keep `email` read-only in the edit form; email changes are out of scope.
- System MUST present edit UI on a dedicated `EditProfileView` screen pushed from `ProfileView` via the existing navigation coordinator.
- System MUST display `avatarUrl` only within `ProfileView`; no other screens are impacted.

## Non-Functional Requirements:

- System MUST compress avatar images to JPEG at 0.8 quality before upload to limit bandwidth and storage usage, consistent with `WishlistService.upload`.
- System MUST place the new `updateUserInfo` method on `AuthenticateServiceProtocol` to respect the existing protocol-based service abstraction.
- System MUST store avatar upload logic inside `AuthenticateService` (or a dedicated `ProfileService`) rather than `WishlistService` to maintain domain separation.
- System MUST preserve backward compatibility with existing `UserModel` consumers; `avatarUrl` must default to `nil` or an empty string to avoid breaking current usages.
