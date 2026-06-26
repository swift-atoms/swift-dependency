# Dependency Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Dependency-injection primitives for Swift — a `Dependency` namespace of typed keys, live/test value variants, and task-local scoped resolution, with zero platform dependencies.

---

## Quick Start

`Dependency` is the vocabulary for type-safe dependency injection: a key type *names* a dependency and supplies a `liveValue` (production) and a `testValue` (tests); `Dependency.Values` holds overrides keyed by those types; `Dependency.Scope` installs them into task-local storage for the duration of an operation. No global singletons, no service locator — resolution is explicit, typed, and scoped.

```swift
import Dependency_Primitives

// Declare a dependency by conforming a key type to `Dependency.Key`.
// `liveValue` is used in production; `testValue` in test contexts.
enum APIBaseURL: Dependency.Key {
    static var liveValue: String { "https://api.example.com" }
    static var testValue: String { "https://stub.local" }
}

// Resolve from the current scope. Unregistered keys return the key's default.
let url = Dependency.Scope.current[APIBaseURL.self]   // "https://api.example.com"

// Override for the duration of an operation — overrides also survive `await`.
let staged = Dependency.Scope.with { values in
    values[APIBaseURL.self] = "https://staging.example.com"
} operation: {
    Dependency.Scope.current[APIBaseURL.self]
}
// staged == "https://staging.example.com"
```

Scopes nest: an inner `with` overrides only the keys it touches and the parent's values are restored on exit. The same `with(_:operation:)` is available in synchronous, throwing (with a typed `throws`), and `async` forms, so scoped dependencies flow across suspension points.

A values container can also be flipped into a *test context*, where unregistered keys resolve to `testValue` instead of `liveValue`:

```swift
import Dependency_Primitives

var values = Dependency.Values.forTesting()
values[APIBaseURL.self]   // "https://stub.local" — the testValue
values.isTestContext      // true
```

`Dependency.Values` is a `Sendable`, copy-on-write value type, so a container can be handed across isolation domains and mutated without disturbing the original.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-dependency-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

One library product. Depends only on the `Witness` primitive — `Dependency.Key` refines `Witness.Protocol`.

| Product | Target | Purpose |
|---------|--------|---------|
| `Dependency Primitives` | `Sources/Dependency Primitives/` | The `Dependency` namespace: `Dependency.Key` (typed keys with `liveValue` / `testValue` variants), `Dependency.Values` (type-safe heterogeneous storage with value semantics), and `Dependency.Scope` (task-local scoped resolution in synchronous, typed-throwing, and `async` forms). |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
