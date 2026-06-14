# Task 5: Update HomeView to Use Real-time Observer

- [ ] 5.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE:
  - Replace the contents of the `.task` modifier:
    - Keep `await authViewModel.getUserInfo()` at the start
    - Remove the `if homeViewModel.myWishlists.isEmpty && homeViewModel.myFriendWishlists.isEmpty` conditional block with `await homeViewModel.getListWishlist()`
    - Add `homeViewModel.startObservingWishlists()` — this method internally handles the initial-load-only loading indicator and registers the real-time listener
