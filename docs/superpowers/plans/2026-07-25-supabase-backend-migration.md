# Supabase Backend Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace FirebaseAuth and Firestore with a single shared Supabase project (Postgres + Auth + Realtime + Edge Functions), consumed directly by both the iOS app and the future web app, with no data migration required (no production users exist).

**Architecture:** One Supabase Cloud project holds Postgres tables (`profiles`, `wishlists`, `wishlist_members`, `wishlist_items`) protected by Row Level Security, Supabase Auth (email/password + Google OAuth), and one Edge Function (`suggest-gifts`) that ports the existing Gemini-calling Cloud Function. The iOS app's `AuthenticateService` and `WishlistService` are rewritten against `supabase-swift` (already a dependency, used today only for Storage) instead of `FirebaseAuth`/`FirebaseFirestore`. Storage and its paths are unchanged.

**Tech Stack:** Swift 5 / iOS (existing app), `supabase-swift` (already linked as product `Supabase`), Supabase CLI, Postgres (SQL migrations), Deno/TypeScript (Edge Functions), XCTest / Swift Testing (existing test targets).

## Global Constraints

- No data/user migration needed — no production users exist yet (per spec).
- Storage stays on Supabase exactly as-is: bucket `Wishie`, paths `avatar/{userId}.jpg` and `wishlist/{fileName}.jpg`. Do not touch `uploadAvatar`, `upload`, or `deleteImageStorage`.
- Auth providers: email/password + Google OAuth only. No Apple Sign-In, no anonymous auth (per spec).
- One Supabase Cloud project, shared by iOS app and the future web app — not one project per client.
- `id` fields that are already client-generated UUID strings (`WishlistModel.id`, `WishlistItem.id`, via `UUID().uuidString`) map onto Postgres `uuid` columns — do not introduce server-generated IDs, existing call sites already construct the ID before persisting.
- Follow the existing test boundary in this codebase: service classes that call the network (Firestore/Supabase) are not directly unit-tested today (see `AuthenticateService`, `WishlistService`) — only pure/static helpers are (`AuthenticateService.resolvedGoogleEmail`, `MostDesiredRule.apply`). Keep new pure mapping/rule logic unit-tested the same way; don't invent network-mocking infrastructure that doesn't already exist in this project.
- Existing consumer-facing mocks (`MockAuthenticateService`, `MockWishlistService`) must keep conforming to the (updated) protocols so `WishieTests` keeps compiling.

---

## Task 1: Create the Supabase project (manual, human-only — not delegated to a subagent)

This task has no code and cannot be performed by a coding agent — it requires an interactive browser session and account ownership.

- [ ] **Step 1: Create the Supabase Cloud project**

Go to https://supabase.com/dashboard, sign in, click "New project". Name it (e.g. `wishie`), pick a region, set a database password (save it somewhere safe — needed for direct Postgres access, not needed day-to-day).

- [ ] **Step 2: Record the project URL and anon key**

In the new project: Settings → API. Copy the "Project URL" and the "anon public" key. These replace the hardcoded values currently in `Wishie/Manager/SupabaseManager.swift:15-16` (which today point at a different Supabase project used only for Storage) — Task 2 wires them in properly via config, but keep them at hand.

- [ ] **Step 3: Enable the Google OAuth provider**

Authentication → Providers → Google. Enable it, and enter the same OAuth client ID/secret pair already configured for Google Sign-In in `GoogleService-Info.plist` (`CLIENT_ID` / reversed client ID) — reuse the existing Google Cloud OAuth client rather than creating a new one, so the iOS app's `GIDSignIn` configuration doesn't need to change.

- [ ] **Step 4: Install the Supabase CLI and log in**

```bash
brew install supabase/tap/supabase
supabase login
```

Confirm the CLI works:

```bash
supabase projects list
```

Expected: the new `wishie` project appears in the list. This CLI is required for Task 2 (pushing migrations) and Task 10 (deploying the Edge Function).

---

## Task 2: Postgres schema and RLS policies

**Files:**
- Create: `supabase/config.toml` (via `supabase init`)
- Create: `supabase/migrations/00000000000001_initial_schema.sql`
- Create: `supabase/migrations/00000000000002_rls_policies.sql`

**Interfaces:**
- Produces: tables `public.profiles`, `public.wishlists`, `public.wishlist_members`, `public.wishlist_items`, and function `public.is_wishlist_member(uuid)` — consumed by every later Swift task via `supabase-swift`'s `.from("<table>")`.

- [ ] **Step 1: Initialize the Supabase project directory**

From the repo root:

```bash
supabase init
```

Expected: creates `supabase/config.toml` and `supabase/migrations/`.

- [ ] **Step 2: Write the schema migration**

Create `supabase/migrations/00000000000001_initial_schema.sql`:

```sql
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  first_name text not null default '',
  last_name text not null default '',
  email text not null default '',
  phone text not null default '',
  date_of_birth date,
  avatar_url text,
  interests text[] not null default '{}',
  has_completed_interests_setup boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.wishlists (
  id uuid primary key,
  name text not null,
  description text not null default '',
  owner_id uuid not null references auth.users (id) on delete cascade,
  due_date timestamptz not null,
  color_theme text,
  is_archived boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.wishlist_members (
  wishlist_id uuid not null references public.wishlists (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (wishlist_id, user_id)
);

create table public.wishlist_items (
  id uuid primary key,
  wishlist_id uuid not null references public.wishlists (id) on delete cascade,
  name text not null,
  description text not null default '',
  image_url text,
  is_picked boolean not null default false,
  picked_by uuid references auth.users (id) on delete set null,
  item_link text not null default '',
  price text,
  is_most_desired boolean not null default false
);

create index wishlist_members_user_id_idx on public.wishlist_members (user_id);
create index wishlist_items_wishlist_id_idx on public.wishlist_items (wishlist_id);
```

- [ ] **Step 3: Write the RLS policies migration**

Create `supabase/migrations/00000000000002_rls_policies.sql`:

```sql
alter table public.profiles enable row level security;
alter table public.wishlists enable row level security;
alter table public.wishlist_members enable row level security;
alter table public.wishlist_items enable row level security;

-- Avoids recursive RLS lookups: policies on wishlists/wishlist_items call this
-- instead of selecting from wishlist_members directly inside their own USING clause.
create or replace function public.is_wishlist_member(p_wishlist_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.wishlist_members
    where wishlist_id = p_wishlist_id and user_id = auth.uid()
  );
$$;

-- profiles: any signed-in user can read any profile (needed to show a
-- wishlist owner's name/avatar); a user can only insert/update their own row.
create policy "profiles_select_authenticated" on public.profiles
  for select to authenticated using (true);
create policy "profiles_insert_self" on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy "profiles_update_self" on public.profiles
  for update to authenticated using (id = auth.uid());

-- wishlists: members can read/update, only the owner can delete, anyone can
-- create a wishlist they own.
create policy "wishlists_select_members" on public.wishlists
  for select to authenticated using (public.is_wishlist_member(id));
create policy "wishlists_insert_owner" on public.wishlists
  for insert to authenticated with check (owner_id = auth.uid());
create policy "wishlists_update_members" on public.wishlists
  for update to authenticated using (public.is_wishlist_member(id));
create policy "wishlists_delete_owner" on public.wishlists
  for delete to authenticated using (owner_id = auth.uid());

-- wishlist_members: members can see the membership list; a user can add
-- themselves (join) or be added/removed by the wishlist owner; a user can
-- remove themselves (leave).
create policy "wishlist_members_select_members" on public.wishlist_members
  for select to authenticated using (public.is_wishlist_member(wishlist_id));
create policy "wishlist_members_insert" on public.wishlist_members
  for insert to authenticated with check (
    user_id = auth.uid()
    or exists (select 1 from public.wishlists w where w.id = wishlist_id and w.owner_id = auth.uid())
  );
create policy "wishlist_members_delete" on public.wishlist_members
  for delete to authenticated using (
    user_id = auth.uid()
    or exists (select 1 from public.wishlists w where w.id = wishlist_id and w.owner_id = auth.uid())
  );

-- wishlist_items: any member of the parent wishlist can read/write items.
create policy "wishlist_items_all_members" on public.wishlist_items
  for all to authenticated
  using (public.is_wishlist_member(wishlist_id))
  with check (public.is_wishlist_member(wishlist_id));
```

- [ ] **Step 4: Push the migrations to the project created in Task 1**

```bash
supabase link --project-ref <project-ref-from-dashboard-url>
supabase db push
```

Expected: CLI reports both migrations applied with no errors. Verify in the dashboard's Table Editor that all four tables and their RLS policies exist.

- [ ] **Step 5: Commit**

```bash
git add supabase/config.toml supabase/migrations
git commit -m "feat: add Supabase schema and RLS policies for auth/wishlist migration"
```

---

## Task 3: Point `SupabaseManager` at the new project and add config

**Files:**
- Modify: `Wishie/Manager/SupabaseManager.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: `SupabaseManager.shared.client` — unchanged type (`SupabaseClient`), now pointed at the project from Task 1. Every later task (Auth, DB, Realtime, Functions) uses this same client.

- [ ] **Step 1: Update the project URL and key**

Edit `Wishie/Manager/SupabaseManager.swift:14-17`, replacing the URL/key with the values recorded in Task 1 Step 2 (the project's Storage bucket `Wishie` must already exist in this project — if it doesn't, create it in the dashboard under Storage, matching the existing `avatar/` and `wishlist/` path usage):

```swift
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "<PROJECT_URL_FROM_TASK_1>")!,
            supabaseKey: "<ANON_KEY_FROM_TASK_1>"
        )
    }
```

- [ ] **Step 2: Build the app**

Run: `xcodebuild -project Wishie.xcodeproj -scheme Wishie -destination 'generic/platform=iOS Simulator' build`
Expected: BUILD SUCCEEDED (no behavior change yet — Storage calls still work against the same client type).

- [ ] **Step 3: Commit**

```bash
git add Wishie/Manager/SupabaseManager.swift
git commit -m "chore: point SupabaseManager at the shared Supabase project"
```

---

## Task 4: `ProfileRow` mapping (pure, unit-tested)

**Files:**
- Create: `Wishie/Models/ProfileRow.swift`
- Test: `WishieTests/ProfileRowTests.swift`

**Interfaces:**
- Produces: `struct ProfileRow: Codable` with snake_case `CodingKeys` matching the `profiles` table from Task 2, `UserModel(row: ProfileRow)`, and `ProfileRow(userId: String, model: UserModel)` — consumed by `AuthenticateService` in Task 6.

- [ ] **Step 1: Write the failing test**

Create `WishieTests/ProfileRowTests.swift`:

```swift
import Testing
@testable import Wishie

struct ProfileRowTests {
    @Test func mapsRowToUserModel() {
        let row = ProfileRow(
            id: "11111111-1111-1111-1111-111111111111",
            firstName: "Ada",
            lastName: "Lovelace",
            email: "ada@example.com",
            phone: "0123456789",
            dateOfBirth: Date(timeIntervalSince1970: 0),
            avatarUrl: "https://example.com/a.jpg",
            interests: ["books", "math"],
            hasCompletedInterestsSetup: true
        )
        let model = UserModel(row: row)
        #expect(model.firstName == "Ada")
        #expect(model.lastName == "Lovelace")
        #expect(model.email == "ada@example.com")
        #expect(model.avatarUrl == "https://example.com/a.jpg")
        #expect(model.interests == ["books", "math"])
        #expect(model.hasCompletedInterestsSetup == true)
    }

    @Test func mapsUserModelToInsertableRow() {
        var model = UserModel()
        model.firstName = "Grace"
        model.lastName = "Hopper"
        model.email = "grace@example.com"
        let row = ProfileRow(userId: "22222222-2222-2222-2222-222222222222", model: model)
        #expect(row.id == "22222222-2222-2222-2222-222222222222")
        #expect(row.firstName == "Grace")
        #expect(row.email == "grace@example.com")
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/ProfileRowTests`
Expected: FAIL — `ProfileRow` and `UserModel(row:)` don't exist.

- [ ] **Step 3: Implement `ProfileRow`**

Create `Wishie/Models/ProfileRow.swift`:

```swift
//
//  ProfileRow.swift
//  Wishie
//

import Foundation

struct ProfileRow: Codable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var dateOfBirth: Date?
    var avatarUrl: String?
    var interests: [String]
    var hasCompletedInterestsSetup: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, phone, interests
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case avatarUrl = "avatar_url"
        case hasCompletedInterestsSetup = "has_completed_interests_setup"
    }

    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        dateOfBirth: Date?,
        avatarUrl: String?,
        interests: [String],
        hasCompletedInterestsSetup: Bool
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.avatarUrl = avatarUrl
        self.interests = interests
        self.hasCompletedInterestsSetup = hasCompletedInterestsSetup
    }

    init(userId: String, model: UserModel) {
        self.init(
            id: userId,
            firstName: model.firstName,
            lastName: model.lastName,
            email: model.email,
            phone: model.phone,
            dateOfBirth: model.dateOfBirth,
            avatarUrl: model.avatarUrl,
            interests: model.interests,
            hasCompletedInterestsSetup: model.hasCompletedInterestsSetup
        )
    }
}

extension UserModel {
    init(row: ProfileRow) {
        self.init()
        self.firstName = row.firstName
        self.lastName = row.lastName
        self.email = row.email
        self.phone = row.phone
        self.dateOfBirth = row.dateOfBirth ?? Date()
        self.avatarUrl = row.avatarUrl
        self.interests = row.interests
        self.hasCompletedInterestsSetup = row.hasCompletedInterestsSetup
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/ProfileRowTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Wishie/Models/ProfileRow.swift WishieTests/ProfileRowTests.swift
git commit -m "feat: add ProfileRow <-> UserModel mapping for Postgres profiles table"
```

---

## Task 5: `WishlistRow`/`WishlistMemberRow`/`WishlistItemRow` mapping (pure, unit-tested)

**Files:**
- Create: `Wishie/Models/WishlistRow.swift`
- Test: `WishieTests/WishlistRowTests.swift`

**Interfaces:**
- Consumes: `WishlistModel`, `WishlistItem`, `WishlistRole` (existing, from `Wishie/Models/WishlistModel.swift` and `Wishie/Models/WishlistItem.swift`).
- Produces: `struct WishlistRow: Codable`, `struct WishlistMemberRow: Codable`, `struct WishlistItemRow: Codable`, and `WishlistModel(row:members:items:)` — consumed by `WishlistService` in Tasks 7–8.

- [ ] **Step 1: Write the failing test**

Create `WishieTests/WishlistRowTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct WishlistRowTests {
    @Test func mapsRowsToWishlistModel() {
        let dueDate = Date(timeIntervalSince1970: 1_700_000_000)
        let row = WishlistRow(
            id: "11111111-1111-1111-1111-111111111111",
            name: "Birthday",
            description: "My birthday list",
            ownerId: "22222222-2222-2222-2222-222222222222",
            dueDate: dueDate,
            colorTheme: "sunset",
            isArchived: false
        )
        let members = [
            WishlistMemberRow(wishlistId: row.id, userId: row.ownerId, role: "owner"),
            WishlistMemberRow(wishlistId: row.id, userId: "33333333-3333-3333-3333-333333333333", role: "member")
        ]
        let items = [
            WishlistItemRow(
                id: "44444444-4444-4444-4444-444444444444",
                wishlistId: row.id,
                name: "Book",
                description: "",
                imageUrl: nil,
                isPicked: false,
                pickedBy: nil,
                itemLink: "",
                price: nil,
                isMostDesired: false
            )
        ]

        let model = WishlistModel(row: row, members: members, items: items)

        #expect(model.id == row.id)
        #expect(model.name == "Birthday")
        #expect(model.userCreateId == row.ownerId)
        #expect(model.members[row.ownerId] == .owner)
        #expect(model.members["33333333-3333-3333-3333-333333333333"] == .member)
        #expect(model.items.count == 1)
        #expect(model.items[0].id == "44444444-4444-4444-4444-444444444444")
    }

    @Test func mapsWishlistModelToInsertableRow() {
        let model = WishlistModel(
            id: "55555555-5555-5555-5555-555555555555",
            name: "Wedding",
            description: "",
            userCreateId: "66666666-6666-6666-6666-666666666666"
        )
        let row = WishlistRow(model: model)
        #expect(row.id == model.id)
        #expect(row.name == "Wedding")
        #expect(row.ownerId == model.userCreateId)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistRowTests`
Expected: FAIL — types don't exist yet.

- [ ] **Step 3: Implement the row types and mapping**

Create `Wishie/Models/WishlistRow.swift`:

```swift
//
//  WishlistRow.swift
//  Wishie
//

import Foundation

struct WishlistRow: Codable {
    var id: String
    var name: String
    var description: String
    var ownerId: String
    var dueDate: Date
    var colorTheme: String?
    var isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case ownerId = "owner_id"
        case dueDate = "due_date"
        case colorTheme = "color_theme"
        case isArchived = "is_archived"
    }

    init(id: String, name: String, description: String, ownerId: String, dueDate: Date, colorTheme: String?, isArchived: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.dueDate = dueDate
        self.colorTheme = colorTheme
        self.isArchived = isArchived
    }

    init(model: WishlistModel) {
        self.init(
            id: model.id,
            name: model.name,
            description: model.description,
            ownerId: model.userCreateId,
            dueDate: model.dueDate,
            colorTheme: model.themeColor,
            isArchived: model.isArchived
        )
    }
}

struct WishlistMemberRow: Codable {
    var wishlistId: String
    var userId: String
    var role: String

    enum CodingKeys: String, CodingKey {
        case wishlistId = "wishlist_id"
        case userId = "user_id"
        case role
    }
}

struct WishlistItemRow: Codable {
    var id: String
    var wishlistId: String
    var name: String
    var description: String
    var imageUrl: String?
    var isPicked: Bool
    var pickedBy: String?
    var itemLink: String
    var price: String?
    var isMostDesired: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, price
        case wishlistId = "wishlist_id"
        case imageUrl = "image_url"
        case isPicked = "is_picked"
        case pickedBy = "picked_by"
        case itemLink = "item_link"
        case isMostDesired = "is_most_desired"
    }

    init(id: String, wishlistId: String, name: String, description: String, imageUrl: String?, isPicked: Bool, pickedBy: String?, itemLink: String, price: String?, isMostDesired: Bool) {
        self.id = id
        self.wishlistId = wishlistId
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.isPicked = isPicked
        self.pickedBy = pickedBy
        self.itemLink = itemLink
        self.price = price
        self.isMostDesired = isMostDesired
    }

    init(wishlistId: String, item: WishlistItem) {
        self.init(
            id: item.id,
            wishlistId: wishlistId,
            name: item.name,
            description: item.description,
            imageUrl: item.image,
            isPicked: item.isPicked,
            pickedBy: item.pickedUserId,
            itemLink: item.itemLink,
            price: item.price,
            isMostDesired: item.isMostDesired
        )
    }

    func toWishlistItem() -> WishlistItem {
        WishlistItem(
            id: id,
            name: name,
            description: description,
            image: imageUrl,
            pickedUserId: pickedBy,
            isPicked: isPicked,
            isMostDesired: isMostDesired,
            itemLink: itemLink,
            price: price
        )
    }
}

extension WishlistModel {
    init(row: WishlistRow, members: [WishlistMemberRow], items: [WishlistItemRow]) {
        var membersDict: [String: WishlistRole] = [:]
        for member in members {
            membersDict[member.userId] = WishlistRole(rawValue: member.role)
        }
        self.init(
            id: row.id,
            name: row.name,
            description: row.description,
            dueDate: row.dueDate,
            items: items.map { $0.toWishlistItem() },
            themeColor: row.colorTheme,
            userCreateId: row.ownerId,
            members: membersDict,
            isArchived: row.isArchived
        )
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistRowTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Wishie/Models/WishlistRow.swift WishieTests/WishlistRowTests.swift
git commit -m "feat: add Postgres row types and mapping for wishlists/members/items"
```

---

## Task 6: Migrate `AuthenticateService` — email/password auth and profile reads/writes

**Files:**
- Modify: `Wishie/Services/AuthenticateService.swift`
- Modify: `Wishie/Screens/Auth/AuthViewModel.swift`
- Modify: `WishieTests/MockAuthenticateService.swift`
- Modify: `WishieTests/AuthenticateServiceGoogleEmailTests.swift`

**Interfaces:**
- Produces: `struct AuthSession: Equatable { let userId: String; let email: String? }` replacing `FirebaseAuth.AuthDataResult` in the protocol; `AuthenticateServiceProtocol` methods now return `AnyPublisher<AuthSession?, Error>` for `login`/`signUp`/`loginWithGoogle`. Consumed by `AuthViewModel` (this task) and Task 6b (Google sign-in, same file).
- Consumes: `ProfileRow`, `UserModel(row:)` from Task 4; `SupabaseManager.shared.client` from Task 3.

- [ ] **Step 1: Replace the protocol's result type**

Edit `Wishie/Services/AuthenticateService.swift` — replace the whole file:

```swift
//
//  AuthenticateService.swift
//  Wishie
//

import Foundation
import UIKit
import Supabase
import GoogleSignIn
import Combine

struct AuthSession: Equatable {
    let userId: String
    let email: String?
}

protocol AuthenticateServiceProtocol {
    func login(_ email: String, _ password: String) -> AnyPublisher<AuthSession?, Error>
    func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<AuthSession?, Error>
    func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthSession?, Error>
    func resetPassword(_ email: String) -> AnyPublisher<Bool, Error>
    func getUserInfo() async throws -> UserModel?
    func getUserInfo(by userId: String) async throws -> UserModel?
    func uploadAvatar(image: UIImage, userId: String) async throws -> String
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws
    func updateUserInterests(userId: String, interests: [String]) async throws
}

class AuthenticateService: AuthenticateServiceProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func login(_ email: String, _ password: String) -> AnyPublisher<AuthSession?, Error> {
        Future<AuthSession?, Error> { [weak self] promise in
            guard let self else { return }
            Task {
                do {
                    let session = try await self.client.auth.signIn(email: email, password: password)
                    promise(.success(AuthSession(userId: session.user.id.uuidString, email: session.user.email)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<AuthSession?, Error> {
        Future<AuthSession?, Error> { [weak self] promise in
            guard let self else { return }
            Task {
                do {
                    let authResponse = try await self.client.auth.signUp(email: signUpRequest.email, password: signUpRequest.password)
                    let userId = authResponse.user.id.uuidString
                    let row = ProfileRow(
                        userId: userId,
                        model: UserModel(
                            firstName: signUpRequest.firstName,
                            lastName: signUpRequest.lastName,
                            email: signUpRequest.email,
                            phone: signUpRequest.phone,
                            dateOfBirth: signUpRequest.dateOfBirth
                        )
                    )
                    try await self.client.from("profiles").insert(row).execute()
                    promise(.success(AuthSession(userId: userId, email: signUpRequest.email)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func resetPassword(_ email: String) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { [weak self] promise in
            guard let self else { return }
            Task {
                do {
                    try await self.client.auth.resetPasswordForEmail(email)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getUserInfo() async throws -> UserModel? {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            return nil
        }
        return try await getUserInfo(by: userId)
    }

    func getUserInfo(by userId: String) async throws -> UserModel? {
        let row: ProfileRow = try await client.from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return UserModel(row: row)
    }

    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "avatar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."])
        }
        let path = "avatar/\(userId).jpg"
        try await SupabaseManager.shared.client.storage
            .from("Wishie")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
        let publicURL = try SupabaseManager.shared.client.storage
            .from("Wishie")
            .getPublicURL(path: path)
            .absoluteString
        return "\(publicURL)?t=\(Int(Date().timeIntervalSince1970))"
    }

    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws {
        struct Update: Encodable {
            var first_name: String
            var last_name: String
            var phone: String
            var date_of_birth: Date
            var avatar_url: String?
        }
        try await client.from("profiles")
            .update(Update(first_name: firstName, last_name: lastName, phone: phone, date_of_birth: dateOfBirth, avatar_url: avatarUrl))
            .eq("id", value: userId)
            .execute()
    }

    func updateUserInterests(userId: String, interests: [String]) async throws {
        struct Update: Encodable {
            var interests: [String]
            var has_completed_interests_setup: Bool
        }
        try await client.from("profiles")
            .update(Update(interests: interests, has_completed_interests_setup: true))
            .eq("id", value: userId)
            .execute()
    }
}
```

Note: `loginWithGoogle` and `resolvedGoogleEmail` are added back in Task 6b below (same file) — this step intentionally omits them so Task 6b's diff is reviewable on its own.

Also add a convenience initializer to `UserModel` used above. Edit `Wishie/Models/UserModel.swift`, adding after the existing `dictionary:` initializer:

```swift
    init(firstName: String, lastName: String, email: String, phone: String, dateOfBirth: Date) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
    }
```

- [ ] **Step 2: Update `AuthViewModel` to use `AuthSession` instead of `FirebaseAuth`**

Edit `Wishie/Screens/Auth/AuthViewModel.swift`:

Replace the import (line 10):
```swift
import Combine
import UIKit
```
(remove `import FirebaseAuth`)

Replace `checkToken()` (lines 34-54):
```swift
    func checkToken() {
        guard let storedId = UserDefaults.standard.string(forKey: userid), !storedId.isEmpty else {
            return
        }
        Task {
            do {
                _ = try await SupabaseManager.shared.client.auth.session
                await self.getUserInfo()
                await MainActor.run {
                    UserDefaults.standard.set(self.userInfo.hasCompletedInterestsSetup, forKey: "hasCompletedInterestsSetup")
                    self.isLoggedIn = true
                }
            } catch {
                await MainActor.run { UserDefaults.standard.removeObject(forKey: self.userid) }
            }
        }
    }
```

Replace the three `receiveValue` closures that unwrap `credential?.user` — in `login` (lines 78-85), `signup` (lines 104-111), and `loginWithGoogle` (lines 135-143) — each currently reads:
```swift
            } receiveValue: { [weak self] credential in
                guard let self,
                      let user = credential?.user
                else { return }
                UserDefaults.standard.setValue(user.uid, forKey: userid)
                isLoggedIn = true
                Task { await self.getUserInfo() }
            }
```
Replace all three occurrences with:
```swift
            } receiveValue: { [weak self] session in
                guard let self,
                      let session
                else { return }
                UserDefaults.standard.setValue(session.userId, forKey: userid)
                isLoggedIn = true
                Task { await self.getUserInfo() }
            }
```

- [ ] **Step 3: Update the mock and existing tests**

Edit `WishieTests/MockAuthenticateService.swift` — replace the whole file:

```swift
//
//  MockAuthenticateService.swift
//  WishieTests
//

import Foundation
import UIKit
import Combine
@testable import Wishie

final class MockAuthenticateService: AuthenticateServiceProtocol {
    var loginWithGoogleResult: AnyPublisher<AuthSession?, Error> = Empty().eraseToAnyPublisher()
    var userToReturn: UserModel? = nil
    var getUserInfoError: Error? = nil

    func login(_ email: String, _ password: String) -> AnyPublisher<AuthSession?, Error> {
        Empty().eraseToAnyPublisher()
    }
    func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<AuthSession?, Error> {
        Empty().eraseToAnyPublisher()
    }
    func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthSession?, Error> {
        loginWithGoogleResult
    }
    func resetPassword(_ email: String) -> AnyPublisher<Bool, Error> {
        Empty().eraseToAnyPublisher()
    }
    func getUserInfo() async throws -> UserModel? {
        if let getUserInfoError { throw getUserInfoError }
        return userToReturn
    }
    func getUserInfo(by userId: String) async throws -> UserModel? {
        nil
    }
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        ""
    }
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws {
    }
    func updateUserInterests(userId: String, interests: [String]) async throws {
    }
}
```

`WishieTests/AuthenticateServiceGoogleEmailTests.swift` calls `AuthenticateService.resolvedGoogleEmail`, which is re-added in Task 6b — leave this file untouched for now; it will fail to compile until Task 6b lands, so do Task 6b in the same working session before running the full suite.

- [ ] **Step 4: Commit**

```bash
git add Wishie/Services/AuthenticateService.swift Wishie/Screens/Auth/AuthViewModel.swift Wishie/Models/UserModel.swift WishieTests/MockAuthenticateService.swift
git commit -m "feat: migrate email/password auth and profile CRUD to Supabase"
```

---

## Task 6b: Migrate Google Sign-In

**Files:**
- Modify: `Wishie/Services/AuthenticateService.swift`
- Test: `WishieTests/AuthenticateServiceGoogleEmailTests.swift` (unchanged, must keep passing)

**Interfaces:**
- Consumes: `AuthSession`, `client` from Task 6.
- Produces: `AuthenticateService.loginWithGoogle`, `AuthenticateService.resolvedGoogleEmail(firebaseEmail:profileEmail:)` (same signature as before — the existing test file is untouched).

- [ ] **Step 1: Run the existing Google-email test to confirm it currently fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthenticateServiceGoogleEmailTests`
Expected: FAIL to build — `AuthenticateService.resolvedGoogleEmail` doesn't exist after Task 6's rewrite.

- [ ] **Step 2: Add `loginWithGoogle` and `resolvedGoogleEmail` back**

Append to `Wishie/Services/AuthenticateService.swift` (inside the `AuthenticateService` class, after `signUp`):

```swift
    func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthSession?, Error> {
        Future<AuthSession?, Error> { [weak self] promise in
            guard let self else { return }
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let googleUser = signInResult?.user,
                      let idToken = googleUser.idToken?.tokenString else {
                    promise(.failure(NSError(domain: "GoogleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token."])))
                    return
                }
                Task {
                    do {
                        let session = try await self.client.auth.signInWithIdToken(
                            credentials: OpenIDConnectCredentials(
                                provider: .google,
                                idToken: idToken,
                                accessToken: googleUser.accessToken.tokenString
                            )
                        )
                        let resolvedEmail = Self.resolvedGoogleEmail(firebaseEmail: session.user.email, profileEmail: googleUser.profile?.email)
                        try await self.createGoogleProfileIfNeeded(userId: session.user.id.uuidString, email: resolvedEmail, profile: googleUser.profile)
                        promise(.success(AuthSession(userId: session.user.id.uuidString, email: resolvedEmail)))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    static func resolvedGoogleEmail(firebaseEmail: String?, profileEmail: String?) -> String {
        if let firebaseEmail, !firebaseEmail.isEmpty {
            return firebaseEmail
        }
        return profileEmail ?? ""
    }

    private func createGoogleProfileIfNeeded(userId: String, email: String, profile: GIDProfileData?) async throws {
        let existing: [ProfileRow] = try await client.from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        guard let existingRow = existing.first else {
            let row = ProfileRow(
                userId: userId,
                model: UserModel(
                    firstName: profile?.givenName ?? "",
                    lastName: profile?.familyName ?? "",
                    email: email,
                    phone: "",
                    dateOfBirth: Date()
                )
            )
            try await client.from("profiles").insert(row).execute()
            return
        }
        if existingRow.email.isEmpty, !email.isEmpty {
            struct Update: Encodable { var email: String }
            try await client.from("profiles")
                .update(Update(email: email))
                .eq("id", value: userId)
                .execute()
        }
    }
```

- [ ] **Step 3: Run the test to verify it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthenticateServiceGoogleEmailTests`
Expected: PASS (all 4 existing cases, unchanged assertions).

- [ ] **Step 4: Commit**

```bash
git add Wishie/Services/AuthenticateService.swift
git commit -m "feat: migrate Google Sign-In to Supabase Auth"
```

---

## Task 7: Migrate `WishlistService` — wishlist CRUD and membership

**Files:**
- Modify: `Wishie/Services/WishlistService.swift`
- Modify: `WishieTests/MockWishlistService.swift`

**Interfaces:**
- Consumes: `WishlistRow`, `WishlistMemberRow`, `WishlistItemRow`, `WishlistModel(row:members:items:)` from Task 5.
- Produces: `createWishlist`, `getWishlist(by:)`, `joinWishlist`, `getUserWishlists`, `deleteWishlist`, `updateWishlistInfo`, `setArchived`, `leaveWishlist` — same signatures as today, now backed by Postgres. `upload`/`deleteImageStorage` untouched (Storage, per Global Constraints).

- [ ] **Step 1: Replace the top of the file and the non-item CRUD methods**

Edit `Wishie/Services/WishlistService.swift` — replace lines 1–137 (imports through the end of `getWishlist(by:)`) with:

```swift
//
//  WishlistService.swift
//  Wishie
//

import Foundation
import Supabase

protocol WishlistServiceProtocol {
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error>
    func upload(image: UIImage, fileName: String) async throws -> String
    func getWishlist(by id: String) async throws -> (WishlistModel, UserModel)
    func joinWishlist(wishListId: String) async throws  -> Result<Bool, Error>
    func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], Error>
    func pickItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>
    func updateWishlistItem(wishlistId: String, itemId: String, newName: String?, newDescription: String?, newImage: UIImage?, newPrice: String?) async throws -> Result<Bool, Error>
    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, Error>
    func updateWishlistInfo(wishlistId: String, name: String, description: String, dueDate: Date, themeColor: String?) async throws -> Result<Bool, Error>
    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, Error>
    func leaveWishlist(wishListId: String) async throws -> Result<Bool, Error>
    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>
    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, Error>
    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error>
    func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void, onError: @escaping (Error) -> Void) -> WishlistSubscription
    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> WishlistSubscription?
}

class WishlistService: WishlistServiceProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error> {
        do {
            try await client.from("wishlists").insert(WishlistRow(model: wishList)).execute()
            try await client.from("wishlist_members").insert(
                WishlistMemberRow(wishlistId: wishList.id, userId: wishList.userCreateId, role: "owner")
            ).execute()
            if !wishList.items.isEmpty {
                let itemRows = wishList.items.map { WishlistItemRow(wishlistId: wishList.id, item: $0) }
                try await client.from("wishlist_items").insert(itemRows).execute()
            }
            return .success(wishList.id)
        } catch {
            return .failure(error)
        }
    }

    func getWishlist(by id: String) async throws -> (WishlistModel, UserModel) {
        let row: WishlistRow = try await client.from("wishlists")
            .select().eq("id", value: id).single().execute().value
        let members: [WishlistMemberRow] = try await client.from("wishlist_members")
            .select().eq("wishlist_id", value: id).execute().value
        let items: [WishlistItemRow] = try await client.from("wishlist_items")
            .select().eq("wishlist_id", value: id).execute().value
        let wishlist = WishlistModel(row: row, members: members, items: items)

        let ownerRow: ProfileRow = try await client.from("profiles")
            .select().eq("id", value: row.ownerId).single().execute().value
        let owner = UserModel(row: ownerRow)
        return (wishlist, owner)
    }
```

- [ ] **Step 2: Replace `joinWishlist` through `getUserWishlists`**

In the same file, replace the existing `joinWishlist` (previously lines 138-173) and `getUserWishlists` (previously lines 174-208) with:

```swift
    func joinWishlist(wishListId: String) async throws -> Result<Bool, any Error> {
        do {
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            try await client.from("wishlist_members").insert(
                WishlistMemberRow(wishlistId: wishListId, userId: userId, role: "member")
            ).execute()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], any Error> {
        do {
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                throw NSError(domain: "WishlistServie", code: 404)
            }
            let memberships: [WishlistMemberRow] = try await client.from("wishlist_members")
                .select()
                .eq("user_id", value: userId)
                .order("joined_at")
                .execute()
                .value

            let wishlists = try await withThrowingTaskGroup(of: (WishlistModel, UserModel).self) { [weak self] group in
                guard let self else { throw NSError(domain: "", code: 404) }
                for membership in memberships {
                    group.addTask {
                        try await self.getWishlist(by: membership.wishlistId)
                    }
                }
                var results: [(WishlistModel, UserModel)] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
            return .success(wishlists)
        } catch {
            return .failure(error)
        }
    }
```

- [ ] **Step 3: Replace `deleteWishlist`, `updateWishlistInfo`, `setArchived`, `leaveWishlist`**

Replace the existing `deleteWishlist` (previously lines 288-317), `updateWishlistInfo` (319-338), `setArchived` (340-350), and `leaveWishlist` (352-384) with:

```swift
    func deleteWishlist(wishlistId: String) async throws -> Result<Bool, any Error> {
        do {
            let items: [WishlistItemRow] = try await client.from("wishlist_items")
                .select().eq("wishlist_id", value: wishlistId).execute().value
            for item in items {
                if let url = item.imageUrl, !url.isEmpty {
                    try await deleteImageStorage(imageUrl: url)
                }
            }
            // wishlist_members and wishlist_items cascade-delete via FK "on delete cascade".
            try await client.from("wishlists").delete().eq("id", value: wishlistId).execute()
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
            struct Update: Encodable {
                var name: String
                var description: String
                var due_date: Date
                var color_theme: String?
            }
            try await client.from("wishlists")
                .update(Update(name: name, description: description, due_date: dueDate, color_theme: themeColor ?? ""))
                .eq("id", value: wishlistId)
                .execute()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, any Error> {
        do {
            struct Update: Encodable { var is_archived: Bool }
            try await client.from("wishlists")
                .update(Update(is_archived: isArchived))
                .eq("id", value: wishlistId)
                .execute()
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
            struct ClearPick: Encodable { var is_picked: Bool; var picked_by: String? }
            try await client.from("wishlist_items")
                .update(ClearPick(is_picked: false, picked_by: nil))
                .eq("wishlist_id", value: wishListId)
                .eq("picked_by", value: userId)
                .execute()
            try await client.from("wishlist_members")
                .delete()
                .eq("wishlist_id", value: wishListId)
                .eq("user_id", value: userId)
                .execute()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
```

- [ ] **Step 4: Update the mock's return types for these methods (already `Result`-based, no signature change) and build**

`WishieTests/MockWishlistService.swift`'s `createWishlist`, `getWishlist`, `joinWishlist`, `getUserWishlists`, `deleteWishlist`, `updateWishlistInfo`, `setArchived`, `leaveWishlist` already match these signatures — no change needed yet (item-related and listener methods are updated in Tasks 8–9).

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'generic/platform=iOS Simulator'`
Expected: build fails only on the remaining Firestore-typed methods (`pickItem` onward, `observeWishlist`/`observeUserWishlistIds`) and `ListenerRegistration` — expected until Tasks 8–9 land. If working through this plan top-to-bottom in one sitting, this is fine; don't stop here to "fix" it.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Services/WishlistService.swift
git commit -m "feat: migrate wishlist CRUD and membership to Postgres"
```

---

## Task 8: Migrate `WishlistService` — item mutations

**Files:**
- Modify: `Wishie/Services/WishlistService.swift`
- Modify: `Wishie/Models/MostDesiredRule.swift`
- Modify: `WishieTests/MostDesiredRuleTests.swift`

**Interfaces:**
- Consumes: `WishlistItemRow` from Task 5.
- Produces: `pickItem`, `updateWishlistItem`, `deleteWishlistItem`, `setMostDesired`, `addWishlistItem` — same signatures, now row-based. `MostDesiredRule.apply` changes signature from `[[String: Any]]` to `wishlistId/itemId` (SQL-driven) — this is a breaking change to `MostDesiredRuleTests`, updated in this task.

- [ ] **Step 1: Update the failing `MostDesiredRuleTests` first**

`MostDesiredRule` previously operated on an in-memory array (because Firestore stored items as one embedded array per wishlist document); with `wishlist_items` as real rows, "clear the old most-desired item" becomes two SQL statements instead of an array transform. Replace `WishieTests/MostDesiredRuleTests.swift` with a test of the new, simpler pure helper that decides *whether* a clear-others step is needed:

```swift
import Testing
@testable import Wishie

struct MostDesiredRuleTests {
    @Test func needsClearingOthersWhenMarkingAnItemMostDesired() {
        #expect(MostDesiredRule.needsClearingOthers(isMostDesired: true) == true)
    }

    @Test func doesNotNeedClearingOthersWhenUnmarking() {
        #expect(MostDesiredRule.needsClearingOthers(isMostDesired: false) == false)
    }
}
```

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/MostDesiredRuleTests`
Expected: FAIL — `needsClearingOthers` doesn't exist yet.

- [ ] **Step 2: Rewrite `MostDesiredRule`**

Replace `Wishie/Models/MostDesiredRule.swift`:

```swift
//
//  MostDesiredRule.swift
//  Wishie
//

import Foundation

/// A wishlist may hold at most one most-desired item. Marking a new item therefore has to
/// clear the flag on whichever item held it before, in the same operation.
enum MostDesiredRule {
    static func needsClearingOthers(isMostDesired: Bool) -> Bool {
        isMostDesired
    }
}
```

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/MostDesiredRuleTests`
Expected: PASS

- [ ] **Step 3: Replace the item-mutation methods in `WishlistService`**

Replace the existing `pickItem` (previously lines 209-237), `updateWishlistItem` (238-286), `deleteWishlistItem` (386-400), `setMostDesired` (402-419), and `addWishlistItem` (421-441) with:

```swift
    func pickItem(wishlistId: String, itemId: String) async throws -> Result<Bool, any Error> {
        do {
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                throw NSError(domain: "WishlistService", code: 404)
            }
            struct Update: Encodable { var is_picked: Bool; var picked_by: String }
            try await client.from("wishlist_items")
                .update(Update(is_picked: true, picked_by: userId))
                .eq("id", value: itemId)
                .execute()
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
            var imageUrl: String?
            if let newImage {
                let existing: WishlistItemRow = try await client.from("wishlist_items")
                    .select().eq("id", value: itemId).single().execute().value
                if let oldUrl = existing.imageUrl, !oldUrl.isEmpty {
                    try? await deleteImageStorage(imageUrl: oldUrl)
                }
                imageUrl = try await upload(image: newImage, fileName: UUID().uuidString)
            }
            struct Update: Encodable {
                var name: String?
                var description: String?
                var image_url: String?
                var price: String?
            }
            try await client.from("wishlist_items")
                .update(Update(name: newName, description: newDescription, image_url: imageUrl, price: newPrice))
                .eq("id", value: itemId)
                .execute()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, any Error> {
        do {
            try await client.from("wishlist_items").delete().eq("id", value: itemId).execute()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, any Error> {
        do {
            if MostDesiredRule.needsClearingOthers(isMostDesired: isMostDesired) {
                struct ClearOthers: Encodable { var is_most_desired: Bool }
                try await client.from("wishlist_items")
                    .update(ClearOthers(is_most_desired: false))
                    .eq("wishlist_id", value: wishlistId)
                    .neq("id", value: itemId)
                    .execute()
            }
            struct Update: Encodable { var is_most_desired: Bool }
            try await client.from("wishlist_items")
                .update(Update(is_most_desired: isMostDesired))
                .eq("id", value: itemId)
                .execute()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error> {
        do {
            try await client.from("wishlist_items")
                .insert(WishlistItemRow(wishlistId: wishlistId, item: item))
                .execute()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
```

`updateWishlistItem`'s `Update` struct sends `nil` fields as JSON `null` via Postgres upsert semantics only if explicitly encoded — since these are plain `Optional<String>` fields on an `Encodable` struct, Swift's `JSONEncoder` (used internally by `supabase-swift`) encodes `nil` as `null`, which would overwrite unrelated columns. To avoid that, keep the existing behavior of skipping absent fields: build the update as `[String: AnyJSON]` instead of a fixed struct — replace the `updateWishlistItem` update block from Step 3 with:

```swift
            var updateFields: [String: AnyJSON] = [:]
            if let newName { updateFields["name"] = .string(newName) }
            if let newDescription { updateFields["description"] = .string(newDescription) }
            if let imageUrl { updateFields["image_url"] = .string(imageUrl) }
            if let newPrice { updateFields["price"] = .string(newPrice) }
            if !updateFields.isEmpty {
                try await client.from("wishlist_items")
                    .update(updateFields)
                    .eq("id", value: itemId)
                    .execute()
            }
```

- [ ] **Step 4: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'generic/platform=iOS Simulator'`
Expected: build fails only on `observeWishlist`/`observeUserWishlistIds`/`ListenerRegistration` — expected until Task 9 lands.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Services/WishlistService.swift Wishie/Models/MostDesiredRule.swift WishieTests/MostDesiredRuleTests.swift
git commit -m "feat: migrate wishlist item mutations to Postgres rows"
```

---

## Task 9: Migrate realtime listeners

**Files:**
- Create: `Wishie/Services/WishlistSubscription.swift`
- Modify: `Wishie/Services/WishlistService.swift`
- Modify: `Wishie/Screens/Home/HomeViewModel.swift`
- Modify: `Wishie/Screens/Detail/WishlistDetailViewController.swift`
- Modify: `WishieTests/MockWishlistService.swift`

**Interfaces:**
- Produces: `protocol WishlistSubscription { func remove() }`, replacing `FirebaseFirestore.ListenerRegistration` everywhere it's used as a type (not just in `WishlistService`).
- Consumes: `client.realtime` / `client.channel(_:)` from `supabase-swift`.

- [ ] **Step 1: Define `WishlistSubscription`**

Create `Wishie/Services/WishlistSubscription.swift`:

```swift
//
//  WishlistSubscription.swift
//  Wishie
//

import Foundation
import Supabase

protocol WishlistSubscription {
    func remove()
}

/// Wraps a Supabase Realtime channel so callers can `remove()` it synchronously,
/// matching the call sites that used to hold a Firestore `ListenerRegistration`.
final class RealtimeChannelSubscription: WishlistSubscription {
    private let channel: RealtimeChannelV2

    init(channel: RealtimeChannelV2) {
        self.channel = channel
    }

    func remove() {
        Task { await channel.unsubscribe() }
    }
}
```

- [ ] **Step 2: Replace `observeWishlist` and `observeUserWishlistIds`**

Replace the existing `observeWishlist` and `observeUserWishlistIds` methods in `Wishie/Services/WishlistService.swift` (previously lines 443-468) with:

```swift
    func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void, onError: @escaping (Error) -> Void) -> WishlistSubscription {
        let channel = client.channel("wishlist-\(id)")
        let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "wishlist_items", filter: "wishlist_id=eq.\(id)")
        Task {
            await channel.subscribe()
            for await _ in changes {
                do {
                    let (wishlist, _) = try await getWishlist(by: id)
                    onChange(wishlist)
                } catch {
                    onError(error)
                }
            }
        }
        return RealtimeChannelSubscription(channel: channel)
    }

    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> WishlistSubscription? {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            return nil
        }
        let channel = client.channel("user-wishlists-\(userId)")
        let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "wishlist_members", filter: "user_id=eq.\(userId)")
        Task {
            await channel.subscribe()
            for await _ in changes {
                let memberships: [WishlistMemberRow] = (try? await client.from("wishlist_members")
                    .select()
                    .eq("user_id", value: userId)
                    .order("joined_at")
                    .execute()
                    .value) ?? []
                onChange(memberships.map { $0.wishlistId })
            }
        }
        Task {
            let memberships: [WishlistMemberRow] = (try? await client.from("wishlist_members")
                .select()
                .eq("user_id", value: userId)
                .order("joined_at")
                .execute()
                .value) ?? []
            onChange(memberships.map { $0.wishlistId })
        }
        return RealtimeChannelSubscription(channel: channel)
    }
```

Also update the protocol declaration in the same file (from Task 7 Step 1, `WishlistServiceProtocol`) — it already declares these two methods returning `WishlistSubscription`/`WishlistSubscription?`, so no further protocol edit is needed here.

- [ ] **Step 3: Update the two call sites**

Edit `Wishie/Screens/Home/HomeViewModel.swift` — change the stored property types (line 18-19):
```swift
    private var userWishlistsListener: WishlistSubscription?
    private var wishlistListeners: [WishlistSubscription] = []
```
The `.remove()` call sites (lines 26-27, 57, 88-89) are unchanged since `WishlistSubscription.remove()` has the same name/shape as Firestore's.

Edit `Wishie/Screens/Detail/WishlistDetailViewController.swift` — change the stored property type (line 50):
```swift
    private var wishlistListener: WishlistSubscription?
```
The `.remove()` and `observeWishlist(...)` call sites (lines 58, 63-64) are unchanged.

- [ ] **Step 4: Update the mock**

Edit `WishieTests/MockWishlistService.swift`:

Replace the `FakeListenerRegistration` class (lines 11-15) and the two Firestore-typed methods (lines 89-95) with:

```swift
final class FakeWishlistSubscription: WishlistSubscription {
    func remove() {}
}
```
and
```swift
    func observeWishlist(by id: String, onChange: @escaping (WishlistModel) -> Void, onError: @escaping (Error) -> Void) -> WishlistSubscription {
        FakeWishlistSubscription()
    }

    func observeUserWishlistIds(onChange: @escaping ([String]) -> Void) -> WishlistSubscription? {
        nil
    }
```

Also remove `import FirebaseFirestore` from the top of that file (line 8) — it's no longer needed.

- [ ] **Step 5: Build and run the full test suite**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED, all tests pass except any still referencing `Firebase*` imports directly (cleaned up in Task 11).

- [ ] **Step 6: Commit**

```bash
git add Wishie/Services/WishlistSubscription.swift Wishie/Services/WishlistService.swift Wishie/Screens/Home/HomeViewModel.swift Wishie/Screens/Detail/WishlistDetailViewController.swift WishieTests/MockWishlistService.swift
git commit -m "feat: migrate wishlist realtime listeners to Supabase Realtime"
```

---

## Task 10: Port `suggestGifts` to a Supabase Edge Function

**Files:**
- Create: `supabase/functions/suggest-gifts/index.ts`
- Create: `supabase/functions/suggest-gifts/giftPrompt.ts`
- Create: `supabase/functions/suggest-gifts/geminiError.ts`
- Modify: `Wishie/Services/GiftSuggestionService.swift`

**Interfaces:**
- Produces: Edge Function `suggest-gifts`, invoked via `client.functions.invoke("suggest-gifts", options:)`, returning `{ "ideas": [...] }` — same JSON shape `GiftIdea.parse(from:)` already expects.

- [ ] **Step 1: Port the prompt-building and error-parsing helpers**

Copy `functions/src/giftPrompt.ts` and `functions/src/geminiError.ts` into `supabase/functions/suggest-gifts/` unchanged in logic, updating only their export style to plain ES module exports usable from Deno (no Node-specific imports in either file — confirm by reading them; if either imports a Node-only module, port only the logic, not the import).

- [ ] **Step 2: Write the Edge Function**

Create `supabase/functions/suggest-gifts/index.ts`:

```typescript
import { buildPrompt, parseGeminiJson } from "./giftPrompt.ts";
import { parseGeminiError } from "./geminiError.ts";

const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent";

const MAX_ATTEMPTS = 4;
const RETRYABLE_STATUS = new Set([429, 500, 503]);
const MAX_RETRY_WAIT_MS = 10_000;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function backoffDelay(attempt: number): number {
  const base = 500 * 2 ** attempt;
  return base + Math.random() * 250;
}

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization header." }), { status: 401 });
  }

  const body = await req.json().catch(() => ({}));
  const interests = Array.isArray(body?.interests) ? body.interests : [];
  const age = typeof body?.age === "number" ? body.age : null;
  const existingItemNames = Array.isArray(body?.existingItemNames) ? body.existingItemNames : [];
  const country = typeof body?.country === "string" ? body.country : null;

  if (interests.length === 0) {
    return new Response(JSON.stringify({ error: "At least one interest is required." }), { status: 400 });
  }

  const prompt = buildPrompt({ interests, age, existingItemNames, country });
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

  const requestInit = {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.9, responseMimeType: "application/json" },
    }),
  };

  let response: Response | undefined;
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    try {
      response = await fetch(`${GEMINI_URL}?key=${geminiApiKey}`, requestInit);
    } catch (err) {
      if (attempt === MAX_ATTEMPTS - 1) {
        return new Response(JSON.stringify({ error: "Could not reach the suggestion service." }), { status: 503 });
      }
      await sleep(backoffDelay(attempt));
      continue;
    }

    if (response.ok) break;

    const errorBody = await response.text().catch(() => "");
    if (!RETRYABLE_STATUS.has(response.status)) {
      return new Response(JSON.stringify({ error: "Suggestion service returned an error." }), { status: 502 });
    }

    const { isDailyQuota, retryDelayMs } = parseGeminiError(errorBody);
    if (isDailyQuota) {
      return new Response(
        JSON.stringify({ error: "You've reached today's gift-suggestion limit. Please try again tomorrow." }),
        { status: 429 },
      );
    }
    if (attempt === MAX_ATTEMPTS - 1) break;
    if (retryDelayMs !== null && retryDelayMs > MAX_RETRY_WAIT_MS) {
      return new Response(JSON.stringify({ error: "The suggestion service is busy right now. Please try again." }), { status: 503 });
    }
    await sleep(retryDelayMs ?? backoffDelay(attempt));
  }

  if (!response || !response.ok) {
    return new Response(JSON.stringify({ error: "The suggestion service is busy right now. Please try again." }), { status: 503 });
  }

  const responseBody = await response.json();
  const text = responseBody?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  let parsed;
  try {
    parsed = parseGeminiJson(text);
  } catch {
    return new Response(JSON.stringify({ error: "Could not parse suggestions." }), { status: 500 });
  }

  return new Response(JSON.stringify({ ideas: parsed.ideas.slice(0, 10) }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

- [ ] **Step 3: Set the secret and deploy**

```bash
supabase secrets set GEMINI_API_KEY=<key-from-the-existing-Firebase-function-config>
supabase functions deploy suggest-gifts
```

Expected: CLI reports the function deployed. Verify in the dashboard under Edge Functions.

- [ ] **Step 4: Update `GiftSuggestionService`**

Replace `Wishie/Services/GiftSuggestionService.swift`:

```swift
import Foundation
import Supabase

protocol GiftSuggestionServiceProtocol {
    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> [GiftIdea]
}

final class GiftSuggestionService: GiftSuggestionServiceProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> [GiftIdea] {
        struct Payload: Encodable {
            var interests: [String]
            var existingItemNames: [String]
            var age: Int?
            var country: String?
        }
        let payload = Payload(interests: interests, existingItemNames: existingItemNames, age: age, country: (country?.isEmpty == false ? country : nil))
        let data: Data = try await client.functions.invoke("suggest-gifts", options: FunctionInvokeOptions(body: payload))
        let json = try JSONSerialization.jsonObject(with: data)
        return GiftIdea.parse(from: json)
    }
}
```

- [ ] **Step 5: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'generic/platform=iOS Simulator'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/suggest-gifts Wishie/Services/GiftSuggestionService.swift
git commit -m "feat: port suggestGifts to a Supabase Edge Function"
```

---

## Task 11: Remove Firebase

**Files:**
- Modify: `Wishie/WishieApp.swift`
- Modify: `Wishie.xcodeproj/project.pbxproj` (remove Firebase package products/dependencies)
- Delete: `GoogleService-Info.plist`
- Modify/Delete: `functions/` (Firebase Cloud Functions project — superseded by `supabase/functions/suggest-gifts`)

**Interfaces:**
- Consumes: nothing new — this is cleanup once Tasks 6–10 are verified working end-to-end against the live Supabase project.

- [ ] **Step 1: Update `WishieApp.swift` bootstrap**

Replace `Wishie/WishieApp.swift`:

```swift
//
//  WishieApp.swift
//  Wishie
//

import SwiftUI
import Combine
import GoogleSignIn

@main
struct WishieApp: App {
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var coordinator: RootNavigationCoordinator
    @State private var isActive: Bool = false

    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: WishieConfig.googleClientID)
        let auth = AuthViewModel()
        _authViewModel = StateObject(wrappedValue: auth)
        _coordinator = StateObject(wrappedValue: RootNavigationCoordinator(authViewModel: auth))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isActive {
                    MainView()
                        .environmentObject(authViewModel)
                        .environmentObject(coordinator)
                } else {
                    Image("LaunchScreen")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
            .preferredColorScheme(.light)
            .animation(.easeInOut(duration: 0.4), value: authViewModel.isLoggedIn)
            .animation(RootNavigationAnimations.welcomeToAuth, value: coordinator.appState)
            .onAppear {
                LocationManager.shared.requestPermission()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring) {
                        isActive = true
                    }
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
```

Create `Wishie/Constants/WishieConfig.swift` to hold the Google OAuth client ID that previously came from `FirebaseApp.app()?.options.clientID` (read out of `GoogleService-Info.plist` before deleting it in Step 3):

```swift
//
//  WishieConfig.swift
//  Wishie
//

enum WishieConfig {
    static let googleClientID = "<CLIENT_ID_from_GoogleService-Info.plist>"
}
```

- [ ] **Step 2: Remove Firebase package dependencies from the Xcode project**

In Xcode: select the `Wishie` project → target `Wishie` → General/Frameworks tab (or Package Dependencies), remove `firebase-ios-sdk` and its products (`FirebaseAuth`, `FirebaseFirestore`, `FirebaseFunctions`, `FirebaseCore`) from the target. Confirm no `import Firebase*` remains:

```bash
grep -rl "import Firebase" Wishie WishieTests
```

Expected: no output.

- [ ] **Step 3: Delete Firebase config and the old Cloud Functions project**

```bash
git rm GoogleService-Info.plist
git rm -r functions
```

- [ ] **Step 4: Full build and test**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED, all tests pass.

- [ ] **Step 5: Commit**

```bash
git add Wishie/WishieApp.swift Wishie/Constants/WishieConfig.swift Wishie.xcodeproj/project.pbxproj
git commit -m "chore: remove Firebase SDK, GoogleService-Info.plist, and legacy Cloud Functions"
```

---

## Self-review notes

- **Spec coverage:** Auth (email/password + Google) → Task 6/6b. Firestore data model → Task 2 (schema/RLS) + Tasks 4–5 (mapping) + Tasks 7–8 (CRUD) + Task 9 (realtime). Edge Function → Task 10. Storage → untouched per Global Constraints, verified unchanged in Tasks 6/7/8. iOS cleanup → Task 11. Manual "create one shared Supabase project" requirement → Task 1.
- **Ambiguity resolved:** `updateWishlistItem`'s partial-update semantics (only overwrite fields the caller actually passed) needed an `AnyJSON`-keyed dictionary instead of a fixed `Encodable` struct, since a fixed struct would serialize absent fields as `null` and silently wipe unrelated columns — called out explicitly in Task 8 Step 3.
- **Sequencing:** Tasks 6 and 6b are split so the diff for Google Sign-In is reviewable independently, but 6b must land before running the full test suite (noted explicitly, since `AuthenticateServiceGoogleEmailTests` references a static method only added in 6b).
