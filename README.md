# swift-dependency

Use this package when code needs to read a value by key from whatever is bound in the current task, and needs nothing beyond live and test defaults and scoped overrides. Start from `Dependency.Key` to declare a dependency, `Dependency.Values` to hold and read bindings, and `Dependency.Scope` to bind them for an operation. When you need a property wrapper, a preview context or keys that must be overridden in tests, use the swift-dependencies package instead.

## Laws

- Reading a key from `Dependency.Values` returns the value stored for that key if there is one, in either context, including an explicitly stored `nil`. Otherwise it returns `testValue` when `isTestContext` is true and `liveValue` when it is false. Defaults are never stored, so they are evaluated again on every read, and changing `isTestContext` changes the defaults while keeping every stored value.
- A key's `testValue` is its `liveValue` unless the key declares one.
- Keys are identified by their type, not their value type: two keys with the same value type keep separate values.
- `Dependency.Values` has value semantics. A copy keeps its own stored values and context. A stored class instance is shared by reference, not copied.
- `merging(_:)` is right-biased: a key stored in both takes the argument's value, a key stored only in the receiver keeps it, and the result's context is always the argument's, even when the argument stores nothing.
- `Dependency.Scope.with` copies the current values, applies the modification to that copy before the operation starts, and binds the copy for the operation only. Untouched keys and the context come from the enclosing scope. The enclosing binding is back in place when the operation returns or throws, and a thrown error reaches the caller unchanged.
- `Dependency.Scope.current` returns a copy: mutating it does not change the active binding, and it stays valid after its scope ends.
- Outside any scope the current values are empty and in live context. Nothing detects that code is running under a test framework; test context comes only from `Dependency.Values.forTesting()` or from setting `isTestContext`.
- Bindings are task-local. Child tasks (`async let`, task groups) inherit the binding across suspension, concurrent scopes in sibling tasks stay isolated from one another, and a detached task starts from the empty live values.
