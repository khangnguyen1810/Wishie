import Testing

/// `APIClientTests` and `APIServiceTests` both drive requests through the shared
/// `MockURLProtocol.requestHandler` static var. `.serialized` only serializes tests within a
/// suite's own subtree, so two independent top-level `.serialized` suites can still run
/// concurrently with *each other* and race on that shared static. Nesting both suites inside
/// this single `.serialized` parent cascades the serialization trait over both, guaranteeing
/// Swift Testing never runs them concurrently against one another.
@Suite(.serialized)
struct MockURLProtocolSharingTests {
}
