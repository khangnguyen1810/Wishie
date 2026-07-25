# Supabase Backend Migration — Design

## Context

Wishie currently uses Firebase (FirebaseAuth, Firestore, Firebase Cloud Functions) as its backend. A companion web app is being planned that needs to share the same database and account system as the iOS app. The owner wants to stop depending on Firebase and needs a shared backend that both clients can call.

No production users exist yet, so no data migration is required — the schema can be redesigned freely.

### Current Firebase usage (inventory)

- **FirebaseAuth** — email/password + Google Sign-In (via `GIDSignIn` → `GoogleAuthProvider`). No Apple Sign-In, no anonymous auth. Used in `AuthenticateService.swift`, `AuthViewModel.swift`, `WishieApp.swift`.
- **Firestore** — collections `users/{uid}`, `users/{uid}/wishlists/{wishlistId}` (membership subcollection), `wishList/{id}` (with an embedded array of item dicts). Uses batched writes, `addSnapshotListener` realtime, `FieldValue.arrayUnion/delete/serverTimestamp`. ~20+ call sites across `WishlistService.swift`, `UserModel.swift`, `WishlistModel.swift`, `HomeViewModel.swift`, `WishListInformationViewModel.swift`, `WishlistDetailViewController.swift`.
- **Firebase Cloud Functions** — one function, `suggestGifts` (Node/TS, Firebase Functions v2 `onCall`), calls Gemini API server-side using a secret `GEMINI_API_KEY`. Called from `GiftSuggestionService.swift`.
- **FirebaseCore** — app bootstrap only.
- **Not used**: Firebase Storage, FCM, Analytics, Crashlytics, Remote Config, Dynamic Links, App Check.
- **Supabase** is already partially integrated: `SupabaseManager.swift` is used only for Storage (bucket `Wishie`, paths `avatar/{userId}.jpg`, `wishlist/{fileName}.jpg`). No Supabase Auth/DB usage yet.

## Goal

Replace FirebaseAuth and Firestore with a single shared Supabase project that both the iOS app and the upcoming web app connect to directly. Keep Supabase Storage as-is. Re-host the `suggestGifts` Cloud Function as a Supabase Edge Function.

## Approach

One Supabase Cloud project (shared by both clients — not one project per app). Supabase itself is the backend: Postgres + Auth + Storage + auto-generated REST/Realtime API, hosted by Supabase. No custom server (Node/NestJS/etc.) needs to be built or hosted. Both apps connect via the Supabase client SDK (`supabase-swift` for iOS, `supabase-js` for the future web app) using the shared project URL + anon key, the same way `GoogleService-Info.plist` configures Firebase today.

Project configuration (schema migrations, RLS policies, Edge Functions) lives as code in a `supabase/` directory managed via the Supabase CLI (`supabase init`, `supabase db push`, `supabase functions deploy`). This is infrastructure-as-code, not a running server process the owner has to operate.

### Alternatives considered

- **Fully custom server** (Node/NestJS or similar + self-managed Postgres/auth): full control, but requires building and operating auth, hosting, and scaling from scratch. Rejected as unnecessary for current scope.
- **Self-hosted BaaS** (Appwrite, PocketBase, self-hosted Supabase): similar capability to managed Supabase but adds server operation (updates, backups, uptime) with no clear benefit here. Rejected.
- **Managed Supabase (chosen)**: lowest migration effort (Storage integration already exists), real Postgres for relational data (wishlist members/items), built-in Auth (email/password + Google OAuth) and RLS, Edge Functions for the one piece of server-side logic needed.

## Data model (Postgres)

Replaces the Firestore structure with normalized relational tables:

- `profiles` (id = auth.uid, first_name, last_name, email, phone, date_of_birth, avatar_url, interests jsonb, has_completed_interests_setup, created_at)
- `wishlists` (id, name, description, owner_id, due_date, color_theme, is_archived, created_at)
- `wishlist_members` (wishlist_id, user_id, role, joined_at) — replaces the Firestore `members` map plus the `users/{uid}/wishlists` subcollection
- `wishlist_items` (id, wishlist_id, name, description, image_url, is_picked, picked_by, item_link, price, is_most_desired) — a real table instead of an embedded array, so item updates (e.g. concurrent "pick" actions) don't require read-modify-write on the whole wishlist document

Row Level Security (RLS) policies on each table enforce that a user can only read/write wishlists they're a member of, replacing Firestore security rules. Because RLS lives in the database, both the iOS app and the web app get consistent authorization without re-implementing it per client.

Supabase Realtime (Postgres logical replication) replaces `addSnapshotListener` for live wishlist/item updates.

## Auth

Supabase Auth, configured with:
- Email/password provider
- Google OAuth provider

This maps 1:1 to the current FirebaseAuth setup (no Apple Sign-In or anonymous auth needed, matching current usage). iOS integrates via the Auth module of `supabase-swift` (already a dependency for Storage).

## Edge Function

`suggestGifts` is rewritten as a Supabase Edge Function (Deno/TypeScript), porting the existing logic from `functions/src/index.ts` (Gemini API call, prompt construction from interests/age/existing items/country, retry on 429/500/503). `GEMINI_API_KEY` is stored as a Supabase Edge Function secret. iOS calls it via `supabase.functions.invoke("suggest-gifts")` instead of `Functions.functions().httpsCallable`.

## iOS app changes

- `AuthenticateService.swift` — FirebaseAuth calls → Supabase Auth calls (sign in/up, password reset, Google OAuth exchange)
- `WishlistService.swift`, `Models/UserModel.swift`, `Models/WishlistModel.swift` — Firestore queries/listeners → Postgres queries via `supabase-swift` + Realtime subscriptions
- `GiftSuggestionService.swift` — Cloud Functions call → Edge Function invoke
- `Services`/`Models` for Storage — unchanged
- Remove FirebaseAuth, FirebaseFirestore, FirebaseFunctions, FirebaseCore from `Package.resolved` once the above are migrated and verified; `GoogleService-Info.plist` can be removed at the same time
- `GoogleSignIn-iOS` SDK stays (still used, now feeding credentials into Supabase Auth's Google OAuth instead of Firebase's)

## Out of scope

- The web app itself (not yet built) — this design only ensures the backend is shared-ready; the web app's implementation is a separate effort.
- Data/user migration — no production users exist, so none is needed.
- Anything already not on Firebase (Storage) — unchanged.
