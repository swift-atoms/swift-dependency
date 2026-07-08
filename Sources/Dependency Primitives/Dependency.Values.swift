// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-primitives
// project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Dependency {
    /// Type-safe storage for dependencies keyed by ``Dependency/Key`` types.
    ///
    /// `Values` provides type-safe heterogeneous storage for dependencies.
    /// Access dependencies using the subscript with a key type:
    ///
    /// ```swift
    /// let client = values[DatabaseClient.self]
    /// values[DatabaseClient.self] = .inMemory
    /// ```
    ///
    /// ## Default Values
    ///
    /// When a dependency is not explicitly registered, the subscript
    /// returns the key's default value:
    /// - `liveValue` in production contexts
    /// - `testValue` in test contexts
    ///
    /// ## Thread Safety
    ///
    /// `Values` is `Sendable` and safe to use across isolation domains.
    /// The storage is copy-on-write and uses value semantics.
    public struct Values: Sendable {
        // Heterogeneous dependency storage: each key type maps to its own `Value`,
        // so the erased element type is load-bearing and cannot be a single generic.
        // swiftlint:disable:next no_any_protocol_existential
        private var storage: [ObjectIdentifier: any Sendable] = [:]
        private var _isTestContext: Bool = false

        /// Creates an empty values container.
        public init() {}
    }
}

// MARK: - Access

extension Dependency.Values {
    /// Whether this context is configured for testing.
    ///
    /// When `true`, unregistered keys return their `testValue`
    /// instead of `liveValue`.
    public var isTestContext: Bool {
        get { _isTestContext }
        set { _isTestContext = newValue }
    }

    /// Access a dependency by its key type.
    ///
    /// - Parameter key: The key type to look up.
    /// - Returns: The registered value, or the default value if not registered.
    public subscript<K: Dependency.Key>(key: K.Type) -> K.Value where K.Value: Copyable {
        get {
            if let value = storage[ObjectIdentifier(key)] as? K.Value {
                return value
            }
            return _isTestContext ? K.testValue : K.liveValue
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }
}

// MARK: - Test Context Configuration

extension Dependency.Values {
    /// Creates a values container configured for testing.
    ///
    /// Values created with this method will return `testValue`
    /// for unregistered keys instead of `liveValue`.
    ///
    /// ```swift
    /// var values = Dependency.Values.forTesting()
    /// // values[SomeKey.self] returns SomeKey.testValue
    /// ```
    public static func forTesting() -> Self {
        var values = Self()
        values._isTestContext = true
        return values
    }
}
