# Login with Google Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up real Google Sign-In behind the existing "Login with Google" button on `LoginView` (currently shows a "not supported" dialog), and add a matching button to `SignUpView`.

**Architecture:** Add the `GoogleSignIn-iOS` SPM package and configure it at app launch from the Firebase client ID. `AuthenticateService` gains a `loginWithGoogle` method that runs the native Google account picker, exchanges the result for a Firebase credential via `GoogleAuthProvider.credential(withIDToken:accessToken:)`, signs in with `Auth.auth().signIn(with:)`, and — on first sign-in — writes a Firestore `users/{uid}` doc. `AuthViewModel` gains a `loginWithGoogle(presentingViewController:)` method that reuses the existing `isShowProgress` / `isShowError` / `isLoggedIn` / `getUserInfo()` pattern from `login()`/`signup()`, and silently swallows the "user canceled" error. A small `UIApplication.topViewController()` helper resolves the view controller GIDSignIn needs to present from. `LoginView`/`SignUpView` buttons call the new `AuthViewModel` method instead of showing the "not supported" dialog.

**Tech Stack:** Swift, SwiftUI, Combine, `GoogleSignIn-iOS` SDK, Firebase Auth (`FirebaseAuth` 12.13.0), Firebase Firestore, Swift Testing (`import Testing`, host-app-based `WishieTests` target).

## Global Constraints

- No UI/layout changes to the existing Google button on `LoginView` — only its `action` closure changes. The new `SignUpView` button reuses the exact same visual treatment (white fill, `google_icon` asset, black "Login with Google" text) already present on `LoginView`.
- `GoogleService-Info.plist` already has `CLIENT_ID` / `REVERSED_CLIENT_ID` (`com.googleusercontent.apps.946256552157-jjh555burl121us1i4g08jrnbp5h9fbq`) from prior work on this branch — no Firebase console step needed as part of this plan.
- New SPM dependency: `https://github.com/google/GoogleSignIn-iOS`, product **`GoogleSignIn`** only (not `GoogleSignInSwift` — we keep the existing custom button UI).
- On Google sign-in cancellation, `AuthViewModel.loginWithGoogle` must silently no-op — no error dialog. Detect this via `(error as NSError).domain == "com.google.GIDSignIn"` and `.code == -5` (`GIDSignInError.Code.canceled`'s raw value) rather than casting to the SDK's typed error, so the check doesn't depend on the exact Swift wrapper shape of whichever `GoogleSignIn-iOS` version resolves.
- On any other failure, reuse the existing `isShowError` / `errorTitle` / `errorMessage = error.localizedDescription` pattern.
- New Firestore user doc fields on first Google sign-in: `firstName`/`lastName` from the Google profile's `givenName`/`familyName` if present else `""`, `email` from the Firebase user, `phone: ""`, `dateOfBirth: Date()`, `hasCompletedInterestsSetup: false`, `createAt: FieldValue.serverTimestamp()` — same shape as the existing `signUp` write in `AuthenticateService.swift`.
- No account-linking logic needed — Firebase project is configured for "multiple accounts per identity" (manual prerequisite, not a code concern; see spec).
- No automated tests are added for the actual GoogleSignIn/Firebase network integration (`AuthenticateService.loginWithGoogle`), per the spec's explicit decision (`docs/superpowers/specs/2026-07-08-login-with-google-design.md`, "Testing / Verification") — there's no existing auth test infrastructure and Firebase's `AuthDataResult` has no public initializer, so it can't be constructed in a test double. Automated tests are added only where they're actually possible: the pure `UIApplication.topViewController` helper (Task 2) and `AuthViewModel.loginWithGoogle`'s failure/cancel branches (Task 4), which don't require a real `AuthDataResult`.
- Build verification command (used throughout this plan):
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
  ```
  Run from `/Users/khanghnguyen/Downloads/Wishie`. Expect `** BUILD SUCCEEDED **` at the end of output.
- Test verification command:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:WishieTests
  ```
  Run from `/Users/khanghnguyen/Downloads/Wishie`. Expect `** TEST SUCCEEDED **`. Adjust the simulator name if `iPhone 16` isn't installed locally (`xcrun simctl list devices available` to check).
- New files under `Wishie/Utils/` and `WishieTests/` are picked up automatically — this project uses Xcode's file-system-synchronized groups (`objectVersion = 77`, `fileSystemSynchronizedGroups` in `project.pbxproj`), so no manual pbxproj/target-membership edit is needed for new `.swift` files placed in an already-synchronized folder.

---

### Task 1: GoogleSignIn SDK integration and app-level wiring

**Files:**
- Modify: `Wishie.xcodeproj/project.pbxproj` (via Xcode GUI, not hand-edited)
- Modify: `Wishie/Info.plist`
- Modify: `Wishie/WishieApp.swift`

**Interfaces:**
- Consumes: nothing from other tasks (leaf/infra task).
- Produces: the `GoogleSignIn` module available to import project-wide; `GIDSignIn.sharedInstance` configured with the Firebase client ID at launch; `.onOpenURL` wired so the Google auth redirect completes the sign-in flow. Tasks 3–6 depend on this being done first (they `import GoogleSignIn` / call `GIDSignIn`).

- [ ] **Step 1 (MANUAL — requires Xcode GUI, cannot be scripted): Add the SPM package**

  1. Open `Wishie.xcodeproj` in Xcode.
  2. Menu bar → **File → Add Package Dependencies…**
  3. In the search field, paste: `https://github.com/google/GoogleSignIn-iOS`
  4. Leave the default dependency rule ("Up to Next Major Version") and click **Add Package**.
  5. In the product-selection sheet, check only **GoogleSignIn** (not `GoogleSignInSwift`), and set "Add to Target" to **Wishie** only (not `WishieTests`/`WishieUITests`).
  6. Click **Add Package**.

- [ ] **Step 2: Verify the package resolved**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  grep -i -A3 "googlesignin" Wishie.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  ```
  Expected: a JSON block showing `"identity" : "googlesignin-ios"` (or similar) with a resolved `"version"`.

- [ ] **Step 3: Add the URL scheme to `Info.plist`**

  In `Wishie/Info.plist`, add a `CFBundleURLTypes` entry directly after the opening `<dict>` tag (before `NSAppTransportSecurity`):

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  	<key>CFBundleURLTypes</key>
  	<array>
  		<dict>
  			<key>CFBundleURLSchemes</key>
  			<array>
  				<string>com.googleusercontent.apps.946256552157-jjh555burl121us1i4g08jrnbp5h9fbq</string>
  			</array>
  		</dict>
  	</array>
  	<key>NSAppTransportSecurity</key>
  	<dict>
  		<key>NSAllowsArbitraryLoads</key>
  		<true/>
  	</dict>
  	<key>NSPhotoLibraryUsageDescription</key>
  	<string>We need access to your photo library to scan QR codes from images.</string>
  	<key>UIAppFonts</key>
  	<array>
  		<string>WorkSans-Regular.ttf</string>
  		<string>WorkSans-Light.ttf</string>
  		<string>WorkSans-Italic.ttf</string>
  		<string>WorkSans-Bold.ttf</string>
  	</array>
  </dict>
  </plist>
  ```

- [ ] **Step 4: Configure `GIDSignIn` and handle the redirect URL in `WishieApp.swift`**

  Replace the full contents of `Wishie/WishieApp.swift` with:

  ```swift
  //
  //  WishieApp.swift
  //  Wishie
  //
  //  Created by Nguyễn Khang Hữu on 5/10/25.
  //

  import SwiftUI
  import Combine
  import Firebase
  import GoogleSignIn

  @main
  struct WishieApp: App {
      @StateObject private var authViewModel: AuthViewModel
      @StateObject private var coordinator: RootNavigationCoordinator
      @State private var isActive: Bool = false
      
      init() {
          if FirebaseApp.app() == nil {
              
              FirebaseApp.configure()
              
          }
          if let clientID = FirebaseApp.app()?.options.clientID {
              GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
          }
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

- [ ] **Step 5: Build to verify it compiles**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
  ```
  Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

  ```bash
  git add Wishie.xcodeproj/project.pbxproj Wishie.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved Wishie/Info.plist Wishie/WishieApp.swift
  git commit -m "feat: add GoogleSignIn-iOS SPM dependency and app-level wiring"
  ```

---

### Task 2: `UIApplication.topViewController()` helper

**Files:**
- Create: `Wishie/Utils/UIApplication+TopViewController.swift`
- Test: `WishieTests/TopViewControllerTests.swift`

**Interfaces:**
- Consumes: nothing from other tasks (leaf component).
- Produces:
  ```swift
  static func topViewController(base: UIViewController? = /* key window's root VC */) -> UIViewController?
  ```
  on `UIApplication`. Tasks 5 and 6 call `UIApplication.topViewController()` (no argument) to find the view controller to present the Google sign-in sheet from.

- [ ] **Step 1: Write the failing tests**

  Create `WishieTests/TopViewControllerTests.swift`:

  ```swift
  //
  //  TopViewControllerTests.swift
  //  WishieTests
  //

  import Testing
  import UIKit
  @testable import Wishie

  struct TopViewControllerTests {
      @Test func returnsBaseWhenNoChildrenOrPresentation() {
          let vc = UIViewController()
          #expect(UIApplication.topViewController(base: vc) === vc)
      }

      @Test func returnsVisibleViewControllerForNavigationController() {
          let root = UIViewController()
          let pushed = UIViewController()
          let nav = UINavigationController(rootViewController: root)
          nav.viewControllers = [root, pushed]
          #expect(UIApplication.topViewController(base: nav) === pushed)
      }

      @Test func returnsSelectedViewControllerForTabBarController() {
          let tabA = UIViewController()
          let tabB = UIViewController()
          let tabBar = UITabBarController()
          tabBar.viewControllers = [tabA, tabB]
          tabBar.selectedViewController = tabB
          #expect(UIApplication.topViewController(base: tabBar) === tabB)
      }

      @Test func recursesThroughNestedNavigationInsideTabBar() {
          let pushed = UIViewController()
          let nav = UINavigationController(rootViewController: UIViewController())
          nav.viewControllers = [UIViewController(), pushed]
          let tabBar = UITabBarController()
          tabBar.viewControllers = [nav]
          tabBar.selectedViewController = nav
          #expect(UIApplication.topViewController(base: tabBar) === pushed)
      }

      @Test func returnsNilForNilBase() {
          #expect(UIApplication.topViewController(base: nil) == nil)
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:WishieTests/TopViewControllerTests
  ```
  Expected: build fails with `cannot find 'topViewController' in scope` (the extension doesn't exist yet).

- [ ] **Step 3: Implement the helper**

  Create `Wishie/Utils/UIApplication+TopViewController.swift`:

  ```swift
  //
  //  UIApplication+TopViewController.swift
  //  Wishie
  //

  import UIKit

  extension UIApplication {
      static func topViewController(base: UIViewController? = keyWindowRootViewController) -> UIViewController? {
          if let nav = base as? UINavigationController {
              return topViewController(base: nav.visibleViewController)
          }
          if let tab = base as? UITabBarController {
              return topViewController(base: tab.selectedViewController)
          }
          if let presented = base?.presentedViewController {
              return topViewController(base: presented)
          }
          return base
      }

      private static var keyWindowRootViewController: UIViewController? {
          UIApplication.shared.connectedScenes
              .compactMap { $0 as? UIWindowScene }
              .flatMap { $0.windows }
              .first { $0.isKeyWindow }?
              .rootViewController
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:WishieTests/TopViewControllerTests
  ```
  Expected: `** TEST SUCCEEDED **`, all 5 tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add Wishie/Utils/UIApplication+TopViewController.swift WishieTests/TopViewControllerTests.swift
  git commit -m "feat: add UIApplication.topViewController() helper"
  ```

---

### Task 3: `AuthenticateService.loginWithGoogle`

**Files:**
- Modify: `Wishie/Services/AuthenticateService.swift`

**Interfaces:**
- Consumes: `GIDSignIn`/`GoogleAuthProvider` from Task 1's SPM dependency.
- Produces:
  ```swift
  func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthDataResult?, Error>
  ```
  on both `AuthenticateServiceProtocol` and `AuthenticateService`. Task 4 (`AuthViewModel.loginWithGoogle`) calls this.

- [ ] **Step 1: Add the method to the protocol**

  In `Wishie/Services/AuthenticateService.swift:14-23`, add the new method to `AuthenticateServiceProtocol` (after `signUp`, before `resetPassword`):

  ```swift
  protocol AuthenticateServiceProtocol {
      func login(_ email: String, _ password: String) -> AnyPublisher<AuthDataResult?, Error>
      func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<FirebaseAuth.AuthDataResult?, Error>
      func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthDataResult?, Error>
      func resetPassword(_ email: String) -> AnyPublisher<Bool, Error>
      func getUserInfo() async throws -> UserModel?
      func getUserInfo(by userId: String) async throws -> UserModel?
      func uploadAvatar(image: UIImage, userId: String) async throws -> String
      func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws
      func updateUserInterests(userId: String, interests: [String]) async throws
  }
  ```

- [ ] **Step 2: Add the `GoogleSignIn` import**

  At the top of `Wishie/Services/AuthenticateService.swift`, add `import GoogleSignIn` alongside the existing imports:

  ```swift
  import Foundation
  import UIKit
  import FirebaseAuth
  import FirebaseFirestore
  import Supabase
  import GoogleSignIn
  import Combine
  ```

- [ ] **Step 3: Implement `loginWithGoogle`, right after `signUp` (before `resetPassword`)**

  ```swift
      func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthDataResult?, Error> {
          return Future<AuthDataResult?, Error> { [weak self] promise in
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
                  let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: googleUser.accessToken.tokenString)
                  self.auth.signIn(with: credential) { result, error in
                      if let error {
                          promise(.failure(error))
                          return
                      }
                      guard let result else {
                          promise(.failure(NSError(domain: "GoogleSignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Authentication result is nil."])))
                          return
                      }
                      Task {
                          do {
                              try await self.createGoogleUserDocumentIfNeeded(for: result.user, profile: googleUser.profile)
                              promise(.success(result))
                          } catch {
                              promise(.failure(error))
                          }
                      }
                  }
              }
          }
          .eraseToAnyPublisher()
      }

      private func createGoogleUserDocumentIfNeeded(for user: FirebaseAuth.User, profile: GIDProfileData?) async throws {
          let userRef = db.collection(WishieConstants.firebaseUserPath).document(user.uid)
          let snapshot = try await userRef.getDocument()
          guard !snapshot.exists else { return }
          let userData: [String: Any] = [
              "uid": user.uid,
              "firstName": profile?.givenName ?? "",
              "lastName": profile?.familyName ?? "",
              "email": user.email ?? "",
              "phone": "",
              "dateOfBirth": Timestamp(date: Date()),
              "hasCompletedInterestsSetup": false,
              "createAt": FieldValue.serverTimestamp()
          ]
          try await userRef.setData(userData)
      }
  ```

- [ ] **Step 4: Build to verify it compiles**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
  ```
  Expected: `** BUILD SUCCEEDED **`. `loginWithGoogle` is not called anywhere yet, so no behavior to manually verify at this point.

- [ ] **Step 5: Commit**

  ```bash
  git add Wishie/Services/AuthenticateService.swift
  git commit -m "feat: add AuthenticateService.loginWithGoogle"
  ```

---

### Task 4: `AuthViewModel.loginWithGoogle`

**Files:**
- Modify: `Wishie/Screens/Auth/AuthViewModel.swift`
- Create: `WishieTests/MockAuthenticateService.swift`
- Test: `WishieTests/AuthViewModelGoogleLoginTests.swift`

**Interfaces:**
- Consumes: `AuthenticateServiceProtocol.loginWithGoogle(presentingViewController:)` from Task 3.
- Produces:
  ```swift
  func loginWithGoogle(presentingViewController: UIViewController)
  ```
  on `AuthViewModel`. Tasks 5 and 6 call this from the `LoginView`/`SignUpView` button actions.

- [ ] **Step 1: Create the mock service used by the tests**

  Create `WishieTests/MockAuthenticateService.swift`:

  ```swift
  //
  //  MockAuthenticateService.swift
  //  WishieTests
  //

  import Foundation
  import UIKit
  import Combine
  import FirebaseAuth
  @testable import Wishie

  final class MockAuthenticateService: AuthenticateServiceProtocol {
      var loginWithGoogleResult: AnyPublisher<AuthDataResult?, Error> = Empty().eraseToAnyPublisher()

      func login(_ email: String, _ password: String) -> AnyPublisher<AuthDataResult?, Error> {
          Empty().eraseToAnyPublisher()
      }
      func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<FirebaseAuth.AuthDataResult?, Error> {
          Empty().eraseToAnyPublisher()
      }
      func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthDataResult?, Error> {
          loginWithGoogleResult
      }
      func resetPassword(_ email: String) -> AnyPublisher<Bool, Error> {
          Empty().eraseToAnyPublisher()
      }
      func getUserInfo() async throws -> UserModel? {
          nil
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

- [ ] **Step 2: Write the failing tests**

  Create `WishieTests/AuthViewModelGoogleLoginTests.swift`:

  ```swift
  //
  //  AuthViewModelGoogleLoginTests.swift
  //  WishieTests
  //

  import Testing
  import UIKit
  import Combine
  @testable import Wishie

  struct AuthViewModelGoogleLoginTests {
      private struct SampleError: LocalizedError {
          var errorDescription: String? { "network unreachable" }
      }

      @Test func failureShowsErrorDialogWithMessage() async throws {
          let mockService = MockAuthenticateService()
          mockService.loginWithGoogleResult = Fail(error: SampleError()).eraseToAnyPublisher()
          let viewModel = AuthViewModel(authService: mockService)

          viewModel.loginWithGoogle(presentingViewController: UIViewController())
          try await Task.sleep(for: .milliseconds(200))

          #expect(viewModel.isShowError == true)
          #expect(viewModel.errorTitle == "Google Login Failed")
          #expect(viewModel.errorMessage == "network unreachable")
          #expect(viewModel.isShowProgress == false)
      }

      @Test func cancelDoesNotShowErrorDialog() async throws {
          let mockService = MockAuthenticateService()
          mockService.loginWithGoogleResult = Fail(
              error: NSError(domain: "com.google.GIDSignIn", code: -5)
          ).eraseToAnyPublisher()
          let viewModel = AuthViewModel(authService: mockService)

          viewModel.loginWithGoogle(presentingViewController: UIViewController())
          try await Task.sleep(for: .milliseconds(200))

          #expect(viewModel.isShowError == false)
          #expect(viewModel.isShowProgress == false)
      }

      @Test func settingLoginInProgressShowsProgressImmediately() {
          let mockService = MockAuthenticateService()
          mockService.loginWithGoogleResult = Empty().eraseToAnyPublisher()
          let viewModel = AuthViewModel(authService: mockService)

          viewModel.loginWithGoogle(presentingViewController: UIViewController())

          #expect(viewModel.isShowProgress == true)
      }
  }
  ```

- [ ] **Step 3: Run tests to verify they fail**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:WishieTests/AuthViewModelGoogleLoginTests
  ```
  Expected: build fails with `value of type 'AuthViewModel' has no member 'loginWithGoogle'`.

- [ ] **Step 4: Implement `loginWithGoogle` on `AuthViewModel`**

  In `Wishie/Screens/Auth/AuthViewModel.swift`, add two private constants next to the existing `private let userid = "userid"` (around line 17):

  ```swift
      private let userid = "userid"
      private let googleSignInErrorDomain = "com.google.GIDSignIn"
      private let googleSignInCanceledCode = -5 // GIDSignInError.Code.canceled's raw value
  ```

  Then add the new method right after `signup(request:)` (before `logOut()`):

  ```swift
      func loginWithGoogle(presentingViewController: UIViewController) {
          self.isShowProgress = true
          authService.loginWithGoogle(presentingViewController: presentingViewController)
              .receive(on: DispatchQueue.main)
              .sink { [weak self] completion in
                  guard let self else { return }
                  self.isShowProgress = false
                  switch completion {
                  case .finished:
                      break
                  case .failure(let error):
                      let nsError = error as NSError
                      if nsError.domain == self.googleSignInErrorDomain, nsError.code == self.googleSignInCanceledCode {
                          return
                      }
                      self.isShowError = true
                      self.errorTitle = "Google Login Failed"
                      self.errorMessage = error.localizedDescription
                  }
              } receiveValue: { [weak self] credential in
                  guard let self,
                        let user = credential?.user
                  else { return }
                  UserDefaults.standard.setValue(user.uid, forKey: userid)
                  isLoggedIn = true
                  Task { await self.getUserInfo() }
              }
              .store(in: &cancellables)
      }
  ```

- [ ] **Step 5: Run tests to verify they pass**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:WishieTests/AuthViewModelGoogleLoginTests
  ```
  Expected: `** TEST SUCCEEDED **`, all 3 tests pass.

- [ ] **Step 6: Commit**

  ```bash
  git add Wishie/Screens/Auth/AuthViewModel.swift WishieTests/MockAuthenticateService.swift WishieTests/AuthViewModelGoogleLoginTests.swift
  git commit -m "feat: add AuthViewModel.loginWithGoogle"
  ```

---

### Task 5: Wire the `LoginView` Google button

**Files:**
- Modify: `Wishie/Screens/Auth/LoginView.swift`

**Interfaces:**
- Consumes: `UIApplication.topViewController()` (Task 2), `AuthViewModel.loginWithGoogle(presentingViewController:)` (Task 4).
- Produces: nothing consumed by later tasks — this is a leaf UI wiring task.

- [ ] **Step 1: Replace the button action**

  In `Wishie/Screens/Auth/LoginView.swift`, find the Google button (currently shows the "not supported" dialog):

  ```swift
              Button(action: {
                  // Login
                  viewModel.isShowError = true
                  viewModel.errorTitle = "Google login is not supported"
                  viewModel.errorMessage = "This feature is currently not supported on app"
              }, label: {
  ```

  Replace just the action closure body with:

  ```swift
              Button(action: {
                  guard let presentingViewController = UIApplication.topViewController() else { return }
                  viewModel.loginWithGoogle(presentingViewController: presentingViewController)
              }, label: {
  ```

  Leave the `label:` closure (icon/text/styling) unchanged.

- [ ] **Step 2: Build to verify it compiles**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
  ```
  Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

  ```bash
  git add Wishie/Screens/Auth/LoginView.swift
  git commit -m "feat: wire LoginView Google button to loginWithGoogle"
  ```

---

### Task 6: Add and wire the `SignUpView` Google button

**Files:**
- Modify: `Wishie/Screens/Auth/SignUpView.swift`

**Interfaces:**
- Consumes: `UIApplication.topViewController()` (Task 2), `AuthViewModel.loginWithGoogle(presentingViewController:)` (Task 4).
- Produces: nothing consumed by later tasks — this is a leaf UI wiring task.

- [ ] **Step 1: Add the Google button after the existing Apple button**

  In `Wishie/Screens/Auth/SignUpView.swift`, find the closing of the "Login with Apple" button:

  ```swift
                      Text("Login with Apple")
                          .font(.wishies(.bold, 20))
                          .foregroundStyle(.white)
                          .frame(maxWidth: .infinity, alignment: .center)
                  }
              })
              .padding(.vertical, 10)
              Spacer()
  ```

  Insert a new Google button between the Apple button and `Spacer()`:

  ```swift
                      Text("Login with Apple")
                          .font(.wishies(.bold, 20))
                          .foregroundStyle(.white)
                          .frame(maxWidth: .infinity, alignment: .center)
                  }
              })
              .padding(.vertical, 10)
              Button(action: {
                  guard let presentingViewController = UIApplication.topViewController() else { return }
                  authVM.loginWithGoogle(presentingViewController: presentingViewController)
              }, label: {
                  ZStack {
                      RoundedRectangle(cornerRadius: 15)
                          .fill(.white)
                          .frame(maxWidth: .infinity)
                          .frame(height: 50)
                          .shadow(color: .black.opacity(0.2), radius: 4, x:0, y: 5)
                      HStack {
                          Image("google_icon")
                              .resizable()
                              .aspectRatio(contentMode: .fit)
                              .frame(width: 20)
                              .padding(.leading, 20)
                      }
                      .frame(maxWidth: .infinity, alignment: .leading)
                      Text("Login with Google")
                          .font(.wishies(.bold, 20))
                          .foregroundStyle(.black)
                          .frame(maxWidth: .infinity, alignment: .center)
                  }
              })
              .padding(.vertical, 10)
              Spacer()
  ```

- [ ] **Step 2: Build to verify it compiles**

  Run from `/Users/khanghnguyen/Downloads/Wishie`:
  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
  ```
  Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

  ```bash
  git add Wishie/Screens/Auth/SignUpView.swift
  git commit -m "feat: add and wire Google button on SignUpView"
  ```

---

### Task 7: Manual end-to-end verification

**Files:** none (verification only).

**Interfaces:**
- Consumes: the fully wired feature from Tasks 1–6.
- Produces: nothing — this is the final task.

- [ ] **Step 1: Run the app on a simulator or device**

  ```bash
  xcodebuild -project Wishie.xcodeproj -scheme Wishie -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
  ```
  Then launch `Wishie.app` on the simulator (via Xcode's Run button, or `xcrun simctl install`/`launch`).

- [ ] **Step 2: New-user signup via Google, from `LoginView`**

  Tap "Login with Google" on the login screen, sign in with a Google account that has never used this app before.
  Expected: lands on the interests-setup screen (not straight into the app). Check the Firebase console → Firestore → `users/{uid}` doc was created with `firstName`/`lastName` from the Google account, `hasCompletedInterestsSetup: false`.

- [ ] **Step 3: Existing-user login via Google**

  Log out, tap "Login with Google" again, sign in with the same Google account.
  Expected: lands straight in the app (no interests-setup screen this time).

- [ ] **Step 4: Cancel mid-flow**

  Tap "Login with Google", then dismiss the Google account picker/sheet without selecting an account.
  Expected: returns cleanly to the login screen, no error dialog shown.

- [ ] **Step 5: New-user signup via Google, from `SignUpView`**

  Log out, navigate to the sign-up screen, tap the new "Login with Google" button with a different, never-used Google account.
  Expected: same as Step 2 — lands on interests-setup, Firestore doc created.

- [ ] **Step 6: Cross-provider email collision**

  Sign up with email/password using the same email address as one of the Google accounts used above.
  Expected: succeeds and creates a second, independent Firebase user (per the "multiple accounts per identity" Firebase setting) — no error.
