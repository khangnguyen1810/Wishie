# Task 1: Update AuthViewModel to fetch and cache user info on auth lifecycle events

- [ ] 1.1: In `Wishie/Screens/Auth/AuthViewModel.swift` UPDATE:
  - Add `@Published var userInfoError: String = ""` after `@Published var forgotenEmail: String = ""`.
  - In the `login()` `receiveValue` closure, after `isLoggedIn = true`, add `Task { await self.getUserInfo() }`.
  - In the `signup()` `receiveValue` closure, after `isLoggedIn = true`, add `Task { await self.getUserInfo() }`.
  - In `checkToken()`, inside the `Task` block after `await MainActor.run { self.isLoggedIn = true }`, add `await self.getUserInfo()`.
  - In `logOut()`, after `isLoggedIn = false`, add `self.userInfo = UserModel()` and `self.userInfoError = ""`.
  - In `getUserInfo()`, replace the `catch` block body from `print(error.localizedDescription)` to `self.userInfoError = error.localizedDescription`.

