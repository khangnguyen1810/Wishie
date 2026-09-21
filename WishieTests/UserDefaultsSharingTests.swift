import Testing

/// `HomeViewModelGetListWishlistTests` and `ArchivedWishlistsViewModelTests` both mutate the
/// shared `UserDefaults.standard` entry at `WishieConstants.userIdKey`: each test sets it up
/// front and removes it in a `defer`. `.serialized` only serializes tests within a suite's own
/// subtree, so two independent top-level `.serialized` (or unserialized) suites can still run
/// concurrently with *each other* — one suite's `defer`-triggered `removeObject` can race another
/// suite's `UserDefaults.standard.string(forKey:)` read while it's suspended mid-`await`, causing
/// nondeterministic early-return-with-empty-results failures. Nesting both suites inside this
/// single `.serialized` parent cascades the serialization trait over both, guaranteeing Swift
/// Testing never runs them concurrently against one another. Mirrors the pattern used for
/// `APIClientTests`/`APIServiceTests` in `NetworkingSharedHandlerTests.swift`.
@Suite(.serialized)
struct UserDefaultsSharingTests {
}
