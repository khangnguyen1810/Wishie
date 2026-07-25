# NestJS Backend Migration — Design

## Context

Wishie currently uses Firebase (FirebaseAuth, Firestore, Firebase Cloud Functions) as its backend, with Supabase Storage already partially integrated. A companion web app is planned that needs to share the same database and account system as the iOS app.

A prior design (`2026-07-25-supabase-backend-migration-design.md`) proposed replacing Firebase with managed Supabase accessed directly by both clients via `supabase-swift`/`supabase-js`, using Postgres RLS for authorization. That direction is superseded by this design: instead of clients talking to Supabase directly, a custom NestJS server sits in front of Supabase and is the only thing either client talks to.

No production users exist yet, so no data migration is required.

## Goal

Stand up a single shared backend — a NestJS server (repo `wishie-server`, deployed on Railway) — that both the iOS app and the future web app call over REST/WebSocket. The server owns all reads/writes to Postgres (via Prisma) and proxies Supabase Auth and Storage on the clients' behalf. Re-implement the existing `suggestGifts` Cloud Function as a NestJS endpoint that calls Gemini directly.

## Approach

Supabase remains the underlying infrastructure (hosted Postgres, Auth, Storage) but is no longer accessed directly by clients. NestJS is the sole entry point:

- **Data access**: Prisma connects directly to the Supabase Postgres connection string (not through PostgREST). Prisma owns schema and migrations, independent of `supabase-js`.
- **Auth**: NestJS's `AuthModule` uses `supabase-js` with the `service_role` key to call Supabase Auth on the client's behalf (`signUp`, `signInWithPassword`, `signInWithIdToken` for Google, `resetPasswordForEmail`), returning Supabase's JWT to the client. A shared `AuthGuard` verifies that JWT (via the Supabase JWT secret) on every other endpoint.
- **Storage**: NestJS receives multipart file uploads from clients and pushes them to the Supabase Storage bucket `Wishie` using `service_role`, returning the public URL. Existing paths are preserved: `avatar/{userId}.jpg`, `wishlist/{fileName}.jpg`.
- **Authorization**: Because Prisma connects directly (bypassing RLS), membership/ownership checks are written by hand in the NestJS service layer before any read/write. RLS stays enabled on the Postgres tables with deny-all policies for `anon`/`authenticated` as defense in depth, in case a client ever obtains a Supabase key directly.
- **Realtime**: Since NestJS is the only writer, there's no need to subscribe to Supabase Realtime. A Socket.io Gateway, with one room per `wishlistId`, emits an event immediately after each successful mutation.
- **Gift suggestions**: `POST /gift-suggestions` calls the Gemini API directly from the NestJS server, replacing the Cloud Function / Edge Function approach.

### Alternatives considered

- **Managed Supabase, direct client access** (the prior design): lowest operational overhead — no server to run — with authorization enforced via RLS. Superseded here in favor of a custom server because the owner wants centralized business logic and authorization in application code rather than in RLS policies, and wants a single backend surface both clients (and any future non-Supabase-aware clients) can call without embedding Supabase credentials.
- **Supabase Edge Functions as a thin server layer**: keeps everything inside Supabase's platform without a separately hosted process, but Deno/Edge Functions are a worse fit for a full REST + WebSocket API than a normal Node server, and don't support long-lived Socket.io connections well. Rejected.
- **Custom NestJS server (chosen)**: full control over authorization logic, request validation, and the API surface both clients consume; Prisma gives typed schema/migrations independent of Supabase tooling; Socket.io gives straightforward realtime without depending on Postgres logical replication.

## Data model (Prisma schema)

Same four entities as the prior design, now defined in Prisma schema (`schema.prisma`) instead of raw SQL migrations, with Prisma managing migrations going forward:

- `Profile` (id = Supabase auth user id, firstName, lastName, email, phone, dateOfBirth, avatarUrl, interests string[], hasCompletedInterestsSetup, createdAt)
- `Wishlist` (id, name, description, ownerId, dueDate, colorTheme, isArchived, createdAt)
- `WishlistMember` (wishlistId, userId, role [`owner`|`member`], joinedAt) — composite primary key on (wishlistId, userId)
- `WishlistItem` (id, wishlistId, name, description, imageUrl, isPicked, pickedBy, itemLink, price, isMostDesired)

`id` fields for `Wishlist` and `WishlistItem` remain client-generated UUID strings (matching existing iOS behavior of generating IDs before persisting), not server-generated.

RLS stays enabled on all four tables in Postgres with deny-all policies for `anon`/`authenticated` roles — this only matters if a Supabase client key is ever used directly against these tables; Prisma's direct Postgres connection is not subject to RLS.

## Auth

`AuthModule` in NestJS, backed by `supabase-js` with the `service_role` key:

- `POST /auth/signup` — creates the Supabase Auth user, inserts the `Profile` row via Prisma, returns the session JWT.
- `POST /auth/login` — `signInWithPassword`, returns the session JWT.
- `POST /auth/google` — accepts a Google ID token from the client (from `GIDSignIn`, as today), exchanges it via `signInWithIdToken`, creates the `Profile` row if it doesn't exist, returns the session JWT.
- `POST /auth/reset-password` — `resetPasswordForEmail`.

A shared `AuthGuard` (NestJS guard) verifies the Supabase JWT on every other route and attaches the authenticated user id to the request context for use in service-layer authorization checks.

iOS drops `supabase-swift`'s Auth module entirely — `AuthenticateService` becomes an HTTP client hitting these NestJS endpoints instead of calling `client.auth.*` directly. The JWT returned is stored (Keychain, as session tokens are today) and attached as a bearer token on subsequent requests.

## Storage

iOS sends multipart uploads to NestJS instead of writing to Supabase Storage directly:

- `POST /profiles/me/avatar` — avatar upload, replaces path `avatar/{userId}.jpg`.
- Item image upload happens as part of item create/update endpoints, replacing path `wishlist/{fileName}.jpg`.

NestJS uses the `service_role` key to write to the `Wishie` bucket and returns the public URL, matching today's URL shape (including the cache-busting query param used for avatars).

## Realtime

A Socket.io `Gateway` in NestJS. Clients connect and join a room named by `wishlistId` (e.g. after opening a wishlist detail screen). After any mutation to that wishlist or its items/members succeeds in the service layer, the gateway emits an event to that room so other connected clients can refetch or apply the change. iOS adds a Socket.io Swift client and replaces its current Firestore `addSnapshotListener` usage with a socket subscription scoped to the open wishlist.

## Gift suggestions

`POST /gift-suggestions` — a NestJS controller/service that builds the same prompt logic as the current Cloud Function (interests, age, existing items, country) and calls the Gemini API directly using a `GEMINI_API_KEY` environment variable on Railway, including the existing retry behavior on 429/500/503. iOS's `GiftSuggestionService` calls this endpoint over plain HTTP instead of `Functions.functions().httpsCallable`.

## REST API surface

```
POST /auth/signup
POST /auth/login
POST /auth/google
POST /auth/reset-password

GET  /profiles/me
PATCH /profiles/me
GET  /profiles/:id
PATCH /profiles/me/interests
POST /profiles/me/avatar

POST /wishlists
GET  /wishlists
GET  /wishlists/:id
PATCH /wishlists/:id
DELETE /wishlists/:id
PATCH /wishlists/:id/archive
POST /wishlists/:id/join
POST /wishlists/:id/leave

POST /wishlists/:id/items
PATCH /wishlists/:id/items/:itemId
DELETE /wishlists/:id/items/:itemId
POST /wishlists/:id/items/:itemId/pick
PATCH /wishlists/:id/items/:itemId/most-desired

POST /gift-suggestions
```

Plus a Socket.io WebSocket namespace, joined per `wishlistId`, for realtime updates.

## iOS app changes

- `SupabaseManager.swift` — removed. Replaced by a plain HTTP client (e.g. `URLSession`-based) configured with the `wishie-server` base URL and bearer-token auth.
- `AuthenticateService.swift` — Supabase Auth SDK calls → HTTP calls to `/auth/*` and `/profiles/*`.
- `WishlistService.swift` — direct Postgres/Supabase queries → HTTP calls to `/wishlists/*`, plus Socket.io subscription for realtime.
- `GiftSuggestionService.swift` — Cloud Functions call → HTTP call to `POST /gift-suggestions`.
- Add a Socket.io Swift client dependency for realtime.
- Remove `supabase-swift` as a dependency once the above are migrated and verified (both the Auth and Storage usage move to the HTTP client).
- `GoogleSignIn-iOS` SDK stays — still used client-side to obtain a Google ID token, which is now sent to `POST /auth/google` instead of exchanged with Supabase directly from the client.

## Out of scope

- The web app itself (not yet built) — this design only ensures the backend is shared-ready.
- Data/user migration — no production users exist, so none is needed.
- Choice of ORM/DB alternatives to Prisma+Postgres — Postgres via Supabase's hosting is retained as the underlying data store; only the access pattern changes.
