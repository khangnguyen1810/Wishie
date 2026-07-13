# Home Card Actions (Long-Press Menu, Edit Info, Archive) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Home's swipe-to-delete card gesture with a native long-press context menu offering Delete/Change info/Archive (My list) or Leave (Friend's list), backed by a new `isArchived` wishlist flag, a new single-page "Edit wishlist info" screen, and a new "Archived wishlists" screen reachable from Profile.

**Architecture:** Extend the existing `WishlistModel` → `WishlistServiceProtocol` → `HomeViewModel` → `HomeView` stack with one new boolean field and two new service methods; add two new self-contained screen+viewmodel pairs (`EditWishlistInfoScreen`, `ArchivedWishlistsView`) following the exact pattern already used by `WishListInformationView`/`WishListInformationViewModel`; delete the now-unneeded custom swipe modifier in favor of SwiftUI's built-in `.contextMenu`.

**Tech Stack:** SwiftUI, Firebase Firestore, Swift Testing (`import Testing`), existing `WishieButton`/`DateInputView`/`GradientTheme` components.

## Global Constraints

- Firestore field name for the new flag is `isArchived` (matches the Swift property name exactly, per spec).
- No confirmation dialog for Archive/Unarchive (reversible); Delete/Leave keep their existing confirmation dialogs unchanged.
- "Change info" and "Archive" only appear on My list cards; Friend's list cards only get "Leave".
- Editing covers only name/description/dueDate/theme — never items or members.
- Follow existing codebase convention: no unit tests for Firestore-touching service/viewmodel methods (none exist today for `WishlistService`/`HomeViewModel`); only pure logic (`WishlistModel(dictionary:)` defaulting) gets a unit test. UI/interaction correctness is verified with a real simulated tap/long-press pass on-device, matching the verification approach already used on this screen this session — not just code review.

---

### Task 1: Add `isArchived` to `WishlistModel`

**Files:**
- Modify: `Wishie/Models/WishlistModel.swift`
- Test: `WishieTests/WishlistModelArchiveTests.swift`

**Interfaces:**
- Produces: `WishlistModel.isArchived: Bool` (stored property, settable), defaults to `false` in both the memberwise `init` and `init(dictionary:)`.

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/WishlistModelArchiveTests.swift`:

```swift
import Testing
@testable import Wishie

struct WishlistModelArchiveTests {

    @Test func memberwiseInitDefaultsToNotArchived() {
        let wishlist = WishlistModel(name: "Test", userCreateId: "u1")
        #expect(wishlist.isArchived == false)
    }

    @Test func dictionaryInitDefaultsToNotArchivedWhenFieldMissing() throws {
        let dictionary: [String: Any] = [
            "id": "1",
            "wishListName": "Test",
            "description": "",
            "userCreateId": "u1"
        ]
        let wishlist = try WishlistModel(dictionary: dictionary)
        #expect(wishlist.isArchived == false)
    }

    @Test func dictionaryInitReadsArchivedTrue() throws {
        let dictionary: [String: Any] = [
            "id": "1",
            "wishListName": "Test",
            "description": "",
            "userCreateId": "u1",
            "isArchived": true
        ]
        let wishlist = try WishlistModel(dictionary: dictionary)
        #expect(wishlist.isArchived == true)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WishieTests/WishlistModelArchiveTests`
Expected: FAIL — `value of type 'WishlistModel' has no member 'isArchived'`

- [ ] **Step 3: Add the field**

In `Wishie/Models/WishlistModel.swift`, add the stored property next to `themeColor`:

```swift
struct WishlistModel: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var dueDate: Date
    var items: [WishlistItem]
    var themeColor: String?
    var userCreateId: String
    let members: [String: WishlistRole]
    var isArchived: Bool
```

Update the memberwise `init` to add the parameter (with default) and assignment:

```swift
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        dueDate: Date = Date(),
        items: [WishlistItem] = [],
        themeColor :String? = nil,
        userCreateId: String,
        members: [String: WishlistRole] = [:],
        isArchived: Bool = false) {
            self.id = id
            self.name = name
            self.description = description
            self.dueDate = dueDate
            self.items = items
            self.userCreateId = userCreateId
            self.themeColor = themeColor
            self.members = members
            self.isArchived = isArchived
        }
```

Update `init(dictionary:)` to read the field, right after `self.themeColor = ...`:

```swift
        self.themeColor = dictionary["colorTheme"] as? String
        self.isArchived = dictionary["isArchived"] as? Bool ?? false
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WishieTests/WishlistModelArchiveTests`
Expected: PASS (3 tests)

- [ ] **Step 5: Full project build check**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **` (the new required-but-defaulted parameter must not break any existing call site — `WishlistModel(...)` is called without `isArchived:` in `CreateWishlistViewModel`, `HomeView`'s tutorial example, and the `#Preview`s; all keep compiling because of the default value)

- [ ] **Step 6: Commit**

```bash
git add Wishie/Models/WishlistModel.swift WishieTests/WishlistModelArchiveTests.swift
git commit -m "feat: add isArchived flag to WishlistModel"
```

---

### Task 2: Add `updateWishlistInfo` and `setArchived` to `WishlistService`

**Files:**
- Modify: `Wishie/Services/WishlistService.swift`

**Interfaces:**
- Consumes: `WishlistModel.isArchived` (Task 1).
- Produces:
  - `WishlistServiceProtocol.updateWishlistInfo(wishlistId: String, name: String, description: String, dueDate: Date, themeColor: String?) async throws -> Result<Bool, Error>`
  - `WishlistServiceProtocol.setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, Error>`

- [ ] **Step 1: Add both methods to the protocol**

In `Wishie/Services/WishlistService.swift`, add to `WishlistServiceProtocol` (after `deleteWishlist`):

```swift
    func updateWishlistInfo(wishlistId: String, name: String, description: String, dueDate: Date, themeColor: String?) async throws -> Result<Bool, Error>
    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, Error>
```

- [ ] **Step 2: Implement both methods on `WishlistService`**

Add after the existing `deleteWishlist(wishlistId:)` implementation (same file):

```swift
    func updateWishlistInfo(
        wishlistId: String,
        name: String,
        description: String,
        dueDate: Date,
        themeColor: String?
    ) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList").document(wishlistId)
            try await docRef.updateData([
                "wishListName": name,
                "description": description,
                "dueDate": Timestamp(date: dueDate),
                "colorTheme": themeColor ?? ""
            ])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func setArchived(wishlistId: String, isArchived: Bool) async throws -> Result<Bool, any Error> {
        do {
            let docRef = db.collection("wishList").document(wishlistId)
            try await docRef.updateData([
                "isArchived": isArchived
            ])
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
```

- [ ] **Step 3: Build check**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

(No unit test here — matches existing convention: `deleteWishlist`/`leaveWishlist`/`setMostDesired` in this same file have no tests either, since they're thin Firestore wrappers. Correctness is verified end-to-end in Task 8.)

- [ ] **Step 4: Commit**

```bash
git add Wishie/Services/WishlistService.swift
git commit -m "feat: add updateWishlistInfo and setArchived to WishlistService"
```

---

### Task 3: `HomeViewModel` — filter archived wishlists, add archive/unarchive

**Files:**
- Modify: `Wishie/Screens/Home/HomeViewModel.swift`

**Interfaces:**
- Consumes: `WishlistModel.isArchived` (Task 1), `WishlistServiceProtocol.setArchived` (Task 2).
- Produces: `HomeViewModel.archiveWishlist(wishlistId: String) async`, `HomeViewModel.unarchiveWishlist(wishlistId: String) async`.

- [ ] **Step 1: Filter archived wishlists out of both derived lists**

In `Wishie/Screens/Home/HomeViewModel.swift`, update both `getListWishlist()` and `refreshWishlists()` — change:

```swift
                   self.myWishlists = list.filter {
                       $0.0.members[userId] == .owner
                   }
                   
                   self.myFriendWishlists = list.filter {
                       $0.0.members[userId] == .member
                   }
```

to:

```swift
                   self.myWishlists = list.filter {
                       $0.0.members[userId] == .owner && !$0.0.isArchived
                   }
                   
                   self.myFriendWishlists = list.filter {
                       $0.0.members[userId] == .member && !$0.0.isArchived
                   }
```

and in `refreshWishlists()`, change:

```swift
                self.myWishlists = list.filter { $0.0.members[userId] == .owner }
                self.myFriendWishlists = list.filter { $0.0.members[userId] == .member }
```

to:

```swift
                self.myWishlists = list.filter { $0.0.members[userId] == .owner && !$0.0.isArchived }
                self.myFriendWishlists = list.filter { $0.0.members[userId] == .member && !$0.0.isArchived }
```

- [ ] **Step 2: Add `archiveWishlist`/`unarchiveWishlist`**

Add after the existing `leaveWishlist(wishlistId:)` method:

```swift
    func archiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: true)
            switch result {
            case .success(let success):
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    func unarchiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: false)
            switch result {
            case .success(let success):
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
```

- [ ] **Step 3: Build check**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Wishie/Screens/Home/HomeViewModel.swift
git commit -m "feat: exclude archived wishlists from Home, add archive/unarchive"
```

---

### Task 4: Extract shared `ThemeColorPicker`

**Files:**
- Create: `Wishie/CustomView/ThemeColorPicker.swift`
- Modify: `Wishie/Screens/CreateList/CreateWishlistPage3.swift`

**Interfaces:**
- Produces: `ThemeColorPicker(selectedTheme: Binding<GradientTheme?>)` — a `View` rendering the theme grid, used by both `CreateWishlistPage3` (this task) and `EditWishlistInfoScreen` (Task 5).

- [ ] **Step 1: Create the shared view**

Create `Wishie/CustomView/ThemeColorPicker.swift`:

```swift
//
//  ThemeColorPicker.swift
//  Wishie
//

import SwiftUI

struct ThemeColorPicker: View {
    @Binding var selectedTheme: GradientTheme?

    private let column = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    var body: some View {
        LazyVGrid(columns: column, spacing: 15) {
            ForEach(GradientTheme.allCases, id: \.self) { theme in
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: theme.primary), Color(hex: theme.secondary)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: .lightYellow, radius: 1, x: -5, y: 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selectedTheme == theme ? .wishiePink : .clear,
                                lineWidth: 3
                            )
                    }
                    .onTapGesture {
                        selectedTheme = theme
                    }
            }
        }
    }
}

#Preview {
    ThemeColorPicker(selectedTheme: .constant(.sunset))
        .padding()
}
```

- [ ] **Step 2: Use it from `CreateWishlistPage3`**

In `Wishie/Screens/CreateList/CreateWishlistPage3.swift`, this exact block currently exists:

```swift
            ScrollView {
                LazyVGrid(columns: column, spacing: 15) {
                    ForEach(GradientTheme.allCases, id: \.self) { theme in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: theme.primary), Color(hex: theme.secondary)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: .lightYellow, radius: 1, x: -5, y: 5)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        createWishlistViewModel.selectedTheme == theme ? .wishiePink : .clear,
                                        lineWidth: 3
                                    )
                            }
                            .onTapGesture {
                                createWishlistViewModel.selectedTheme = theme
                            }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
```

Replace that entire block (the outer `ScrollView` down to `.scrollIndicators(.hidden)`) with:

```swift
            ScrollView {
                ThemeColorPicker(selectedTheme: $createWishlistViewModel.selectedTheme)
                    .padding()
            }
            .scrollIndicators(.hidden)
```

Also delete the now-unused `column` property earlier in the same file:

```swift
    let column = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
```

(`ThemeColorPicker` owns its own copy of this grid definition — see Task 4 Step 1 — so `CreateWishlistPage3` no longer needs one.)

- [ ] **Step 3: Build check**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Visual check via existing preview**

Open `CreateWishlistPage3` and `ThemeColorPicker` previews in Xcode canvas (or render via the same `UIHostingController`-to-PNG technique used earlier this session if canvas isn't available) — confirm the theme grid in `CreateWishlistPage3` looks pixel-identical to before the extraction (4 gradient swatches in a 2-column grid, selected one has a pink border).

- [ ] **Step 5: Commit**

```bash
git add Wishie/CustomView/ThemeColorPicker.swift Wishie/Screens/CreateList/CreateWishlistPage3.swift
git commit -m "refactor: extract ThemeColorPicker from CreateWishlistPage3"
```

---

### Task 5: "Change info" — `EditWishlistInfoScreen` + `EditWishlistInfoViewModel`

**Files:**
- Create: `Wishie/Screens/EditWishlistInfo/EditWishlistInfoViewModel.swift`
- Create: `Wishie/Screens/EditWishlistInfo/EditWishlistInfoScreen.swift`
- Modify: `Wishie/Models/Route.swift`
- Modify: `Wishie/Screens/Home/HomeView.swift`

**Interfaces:**
- Consumes: `WishlistServiceProtocol.getWishlist(by:)` (existing), `WishlistServiceProtocol.updateWishlistInfo` (Task 2), `ThemeColorPicker` (Task 4), `DateInputView(isCreating:date:)` (existing), `WishieButton` (existing).
- Produces: `Route.editWishlistInfo(wishlistId: String)` case; `EditWishlistInfoScreen(wishlistId: String, path: Binding<NavigationPath>)`.

- [ ] **Step 1: Add the Route case**

In `Wishie/Models/Route.swift`, add:

```swift
enum Route: Hashable {
    case createNew
    case scanQRCode
    case createSuccess(wishListId: String)
    case qrCodeScreen(wishlistId: String)
    case wishListInfoScreen(wishlistId: String)
    case wishListDetailScreen(wishlistId: String, isFromInfo: Bool)
    case editProfile
    case editInterests
    case editWishItem(wishlistId: String, isEdit: Bool, wishItem: WishlistItem)
    case editWishlistInfo(wishlistId: String)
}
```

- [ ] **Step 2: Create the view model**

Create `Wishie/Screens/EditWishlistInfo/EditWishlistInfoViewModel.swift`, following the exact loading pattern already used by `WishListInformationViewModel`:

```swift
//
//  EditWishlistInfoViewModel.swift
//  Wishie
//

import Foundation

@MainActor
class EditWishlistInfoViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var dueDate: Date = Date()
    @Published var selectedTheme: GradientTheme?
    @Published var isLoading: Bool = false
    @Published var didSave: Bool = false

    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    func load(wishlistId: String) async {
        do {
            isLoading = true
            let wishlist = try await service.getWishlist(by: wishlistId).0
            name = wishlist.name
            description = wishlist.description
            dueDate = wishlist.dueDate
            selectedTheme = wishlist.theme
            isLoading = false
        } catch {
            isLoading = false
            print(error)
        }
    }

    func save(wishlistId: String) async {
        do {
            isLoading = true
            let result = try await service.updateWishlistInfo(
                wishlistId: wishlistId,
                name: name,
                description: description,
                dueDate: dueDate,
                themeColor: selectedTheme?.rawValue
            )
            isLoading = false
            switch result {
            case .success:
                didSave = true
            case .failure(let error):
                print(error)
            }
        } catch {
            isLoading = false
            print(error)
        }
    }
}
```

- [ ] **Step 3: Create the screen**

Create `Wishie/Screens/EditWishlistInfo/EditWishlistInfoScreen.swift`, reusing the exact field styles from `CreateWishlistPage1` (name/description/due date) plus `ThemeColorPicker` (Task 4):

```swift
//
//  EditWishlistInfoScreen.swift
//  Wishie
//

import SwiftUI

struct EditWishlistInfoScreen: View {
    let wishlistId: String
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditWishlistInfoViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case description
    }

    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image("back_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17)
                    }
                    .onTapGesture {
                        dismiss()
                    }
                    .padding(.trailing, 10)
            } center: {
                Text("Change info")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Wishlist name", text: $viewModel.name)
                        .font(.wishies(.regular, 17))
                        .padding(.horizontal, 15)
                        .textInputAutocapitalization(.never)
                        .background {
                            RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                                .frame(height: 56)
                        }
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .focused($focusedField, equals: .name)

                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("Description...", text: $viewModel.description, axis: .vertical)
                            .font(.wishies(.regular, 17))
                            .padding(10)
                            .frame(maxHeight: 100, alignment: .topLeading)
                            .lineLimit(2...4)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.lightYellow)
                            )
                            .onChange(of: viewModel.description) { _, newValue in
                                if newValue.count > 200 {
                                    viewModel.description = String(newValue.prefix(200))
                                }
                            }
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }
                            .focused($focusedField, equals: .description)
                        Text("\(viewModel.description.count)/200")
                            .font(.caption)
                            .foregroundColor(viewModel.description.count == 200 ? .red : .gray)
                    }

                    DateInputView(isCreating: .constant(true), date: $viewModel.dueDate)

                    Text("Choose your theme color")
                        .font(.wishies(.regular, 17))
                        .padding(.top)

                    ThemeColorPicker(selectedTheme: $viewModel.selectedTheme)
                }
                .padding(.top, 20)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }

            WishieButton(
                title: "Save changes",
                enabled: !viewModel.name.isEmpty
            ) {
                Task { await viewModel.save(wishlistId: wishlistId) }
            }
            .padding(.bottom, 20)
        }
        .showFullScreenDialog($viewModel.isLoading)
        .task {
            await viewModel.load(wishlistId: wishlistId)
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                dismiss()
            }
        }
    }
}

#Preview {
    EditWishlistInfoScreen(
        wishlistId: "136D375B-7015-4C9A-97BE-830C5C46F24A",
        path: .constant(NavigationPath())
    )
}
```

- [ ] **Step 4: Wire the route into `HomeView`'s navigation destination**

In `Wishie/Screens/Home/HomeView.swift`, in the `.navigationDestination(for: Route.self)` switch, add a case (next to `.wishListInfoScreen`):

```swift
                case .editWishlistInfo(wishlistId: let id):
                    EditWishlistInfoScreen(wishlistId: id, path: $path)
```

- [ ] **Step 5: Build check**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/EditWishlistInfo Wishie/Models/Route.swift Wishie/Screens/Home/HomeView.swift
git commit -m "feat: add Change info edit screen for wishlist name/description/date/theme"
```

---

### Task 6: Replace swipe-to-delete with long-press context menu

**Files:**
- Modify: `Wishie/Screens/Home/HomeView.swift`
- Delete: `Wishie/Helper/SwipeToDeleteModifier.swift`
- Delete: `WishieTests/SwipeRevealStateTests.swift`

**Interfaces:**
- Consumes: `HomeViewModel.archiveWishlist(wishlistId:)` (Task 3), `Route.editWishlistInfo(wishlistId:)` (Task 5).

- [ ] **Step 1: Replace `.swipeToDelete` with `.contextMenu` on the "My list" row**

In `Wishie/Screens/Home/HomeView.swift`, in the `.myList` `ForEach` block, replace:

```swift
                                            .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                            .swipeToDelete(tint: .wishiePink, label: "Delete") {
                                                selectedWishlist = wishlist
                                                showDeleteConfirm = true
                                            }
                                        }
                                    case .friendsList:
```

with:

```swift
                                            .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                            .contextMenu {
                                                Button {
                                                    path.append(Route.editWishlistInfo(wishlistId: wishlist.0.id))
                                                } label: {
                                                    Label("Change info", systemImage: "pencil")
                                                }
                                                Button {
                                                    Task { await homeViewModel.archiveWishlist(wishlistId: wishlist.0.id) }
                                                } label: {
                                                    Label("Archive", systemImage: "archivebox")
                                                }
                                                Button(role: .destructive) {
                                                    selectedWishlist = wishlist
                                                    showDeleteConfirm = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    case .friendsList:
```

- [ ] **Step 2: Replace `.swipeToDelete` with `.contextMenu` on the "Friend's list" row**

In the same file, in the `.friendsList` `ForEach` block, replace:

```swift
                                            .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                            .swipeToDelete(tint: .wishiePink, label: "Leave") {
                                                selectedWishlist = wishlist
                                                showLeaveConfirm = true
                                            }
                                        }
                                    }
                                }
```

with:

```swift
                                            .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    selectedWishlist = wishlist
                                                    showLeaveConfirm = true
                                                } label: {
                                                    Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                                                }
                                            }
                                        }
                                    }
                                }
```

- [ ] **Step 3: Delete the now-unused swipe modifier and its test**

```bash
rm Wishie/Helper/SwipeToDeleteModifier.swift
rm WishieTests/SwipeRevealStateTests.swift
```

- [ ] **Step 4: Build check**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **` (confirms no other file references `.swipeToDelete`, `SwipeToDeleteModifier`, or `swipeRevealState`)

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/Home/HomeView.swift
git add -u Wishie/Helper/SwipeToDeleteModifier.swift WishieTests/SwipeRevealStateTests.swift
git commit -m "feat: replace swipe-to-delete with long-press context menu on Home cards"
```

---

### Task 7: "Archived wishlists" screen, reachable from Profile

**Files:**
- Create: `Wishie/Screens/Archived/ArchivedWishlistsViewModel.swift`
- Create: `Wishie/Screens/Archived/ArchivedWishlistsView.swift`
- Modify: `Wishie/Models/Route.swift`
- Modify: `Wishie/Screens/Profile/ProfileView.swift`

**Interfaces:**
- Consumes: `WishlistServiceProtocol.getUserWishlists()` (existing), `.setArchived` (Task 2), `.deleteWishlist` (existing), `HomeItemViewCell(item:)` (existing).
- Produces: `Route.archivedWishlists` case; `ArchivedWishlistsView`.

- [ ] **Step 1: Add the Route case**

In `Wishie/Models/Route.swift`, add `case archivedWishlists` (after `editWishlistInfo`):

```swift
    case editWishlistInfo(wishlistId: String)
    case archivedWishlists
```

- [ ] **Step 2: Create the view model**

Create `Wishie/Screens/Archived/ArchivedWishlistsViewModel.swift`:

```swift
//
//  ArchivedWishlistsViewModel.swift
//  Wishie
//

import Foundation

@MainActor
class ArchivedWishlistsViewModel: ObservableObject {
    @Published var archivedWishlists: [(WishlistModel, UserModel)] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    func loadArchivedWishlists() async {
        do {
            isLoading = true
            guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
                isLoading = false
                return
            }
            let result = try await service.getUserWishlists()
            switch result {
            case .success(let list):
                isLoading = false
                self.archivedWishlists = list.filter {
                    $0.0.members[userId] == .owner && $0.0.isArchived
                }
            case .failure(let error):
                isLoading = false
                self.errorMessage = error.localizedDescription
            }
        } catch {
            isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }

    func unarchiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: false)
            switch result {
            case .success:
                await loadArchivedWishlists()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteWishlist(wishlistId: String) async {
        do {
            let result = try await service.deleteWishlist(wishlistId: wishlistId)
            switch result {
            case .success:
                await loadArchivedWishlists()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 3: Create the screen**

Create `Wishie/Screens/Archived/ArchivedWishlistsView.swift`. Cards use `HomeItemViewCell` with a `.contextMenu` (no `NavigationLink` — tapping an archived card does nothing since you can't manage gifts on an archived wishlist without unarchiving first) and the existing `showDialogIfNeeded` delete-confirmation pattern copied from `HomeView`:

```swift
//
//  ArchivedWishlistsView.swift
//  Wishie
//

import SwiftUI

struct ArchivedWishlistsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ArchivedWishlistsViewModel()
    @State private var selectedWishlistId: String?
    @State private var showDeleteConfirm = false

    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image("back_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17)
                    }
                    .onTapGesture { dismiss() }
                    .padding(.trailing, 10)
            } center: {
                Text("Archived wishlists")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            if viewModel.archivedWishlists.isEmpty {
                VStack(spacing: 12) {
                    Text("No archived wishlists yet")
                        .font(.wishies(.bold, 18))
                        .foregroundStyle(.black)
                    Text("Wishlists you archive from Home will show up here.")
                        .font(.wishies(.regular, 14))
                        .foregroundStyle(.darkGrey)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.archivedWishlists, id: \.0.id) { wishlist in
                            HomeItemViewCell(item: wishlist)
                                .padding(.vertical, 14)
                                .contextMenu {
                                    Button {
                                        Task { await viewModel.unarchiveWishlist(wishlistId: wishlist.0.id) }
                                    } label: {
                                        Label("Unarchive", systemImage: "arrow.uturn.backward")
                                    }
                                    Button(role: .destructive) {
                                        selectedWishlistId = wishlist.0.id
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.loadArchivedWishlists()
                }
            }
        }
        .showFullScreenDialog($viewModel.isLoading)
        .showDialogIfNeeded(
            $showDeleteConfirm,
            title: "Are you sure to delete it?",
            message: "When you delete this wishlist, you can't recover it again.",
            onOk: {
                Task {
                    guard let id = selectedWishlistId else { return }
                    await viewModel.deleteWishlist(wishlistId: id)
                }
                showDeleteConfirm = false
            },
            onCancel: {
                showDeleteConfirm = false
            }
        )
        .task {
            await viewModel.loadArchivedWishlists()
        }
    }
}

#Preview {
    ArchivedWishlistsView()
}
```

- [ ] **Step 4: Wire the entry point into `ProfileView`**

In `Wishie/Screens/Profile/ProfileView.swift`, add a tappable row after the existing `profileInfoRow(label: "Interests", ...)` block (inside the same `VStack(spacing: 0) { ... }`):

```swift
                            profileInfoRow(label: "Archived wishlists", value: "")
                                .onTapGesture {
                                    path.append(Route.archivedWishlists)
                                }
```

Add the destination case to the existing `.navigationDestination(for: Route.self)` switch in the same file:

```swift
                case .archivedWishlists:
                    ArchivedWishlistsView()
```

- [ ] **Step 5: Build check**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/Archived Wishie/Models/Route.swift Wishie/Screens/Profile/ProfileView.swift
git commit -m "feat: add Archived wishlists screen reachable from Profile"
```

---

### Task 8: Full-project test suite + real interactive verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full unit test suite**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WishieTests`
Expected: PASS for all tests except the pre-existing, unrelated `TopViewControllerTests` failures already known from earlier this session (confirm no *new* failures were introduced).

- [ ] **Step 2: Install the build on a simulator with a live session and reach Home**

```bash
xcrun simctl list devices | grep Booted   # find/confirm a booted iOS 18.6 simulator
xcrun simctl install <UDID> "$(find ~/Library/Developer/Xcode/DerivedData -name Wishie.app -path '*Debug-iphonesimulator*' | head -1)"
xcrun simctl launch <UDID> com.khangnguyen.Wishie
```
Screenshot (`xcrun simctl io <UDID> screenshot out.png`) to confirm Home loads with real wishlist cards.

- [ ] **Step 3: Verify tap-to-navigate still works alongside the new context menu**

Using the CGEvent-based synthetic click established earlier this session (`CGEvent(mouseEventSource:mouseType:mouseCursorPosition:mouseButton:)`, posted via `.post(tap: .cghidEventTap)`), click a My list card's blank area (not a button/badge) and screenshot. Expected: navigates to `WishlistDetailScreen`. This is the exact interaction that broke twice already on this screen — must be re-confirmed after adding `.contextMenu`, not assumed safe.

- [ ] **Step 4: Verify the long-press context menu**

Post a `leftMouseDown` at a My list card's coordinates, hold (`usleep` ~700ms, longer than SwiftUI's ~500ms long-press threshold), then `leftMouseUp`. Screenshot. Expected: context menu appears showing "Change info", "Archive", "Delete". Repeat for a Friend's list card — expect only "Leave".

- [ ] **Step 5: Verify Archive → Archived screen → Unarchive round-trip**

- Long-press a My list card → tap "Archive". Screenshot Home: the card should be gone from "My list".
- Navigate to Profile → "Archived wishlists". Screenshot: the archived card should appear there.
- Long-press it → tap "Unarchive". Screenshot: card disappears from Archived.
- Navigate back to Home → "My list". Screenshot: card reappears.

- [ ] **Step 6: Verify "Change info" edit flow**

Long-press a My list card → tap "Change info". Screenshot: `EditWishlistInfoScreen` opens pre-filled with the card's current name/description/date/theme. Change the name, tap "Save changes". Screenshot Home: the card's name updates without a manual pull-to-refresh (confirms the existing Firestore listener picks up the change).

- [ ] **Step 7: Clean up**

```bash
xcrun simctl terminate <UDID> com.khangnguyen.Wishie
```

No commit for this task (verification only) — if any step in this task reveals a bug, fix it as a new task appended to this plan (with its own file/step/commit structure) rather than patching silently.
