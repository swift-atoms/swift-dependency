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

public import Witness_Primitives

extension Dependency {
    /// A key for dependency injection with live/test variants.
    ///
    /// Conform your dependency types to this protocol to enable
    /// registration in ``Dependency/Values``:
    ///
    /// ```swift
    /// struct DatabaseClient: Dependency.Key {
    ///     typealias Value = DatabaseClientImpl
    ///     static var liveValue: Value { .postgres }
    ///     static var testValue: Value { .inMemory }
    /// }
    /// ```
    ///
    /// ## Live vs Test Values
    ///
    /// The protocol distinguishes between:
    /// - `liveValue`: Used in production code
    /// - `testValue`: Used in test contexts (defaults to `liveValue`)
    ///
    /// This enables dependency injection patterns where tests can
    /// automatically use mock implementations.
    ///
    /// ## Usage
    ///
    /// Access dependencies through the values subscript:
    ///
    /// ```swift
    /// let client = Dependency.Scope.current[DatabaseClient.self]
    /// ```
    ///
    /// Register dependencies in a scope:
    ///
    /// ```swift
    /// Dependency.Scope.with { values in
    ///     values[DatabaseClient.self] = .custom
    /// } operation: {
    ///     // Uses .custom here
    /// }
    /// ```
    public protocol Key: Sendable, Witness.`Protocol` {
        /// The value type this key provides.
        associatedtype Value: ~Copyable & Sendable

        /// The default value for production use.
        static var liveValue: Value { get }

        /// The default value for testing (defaults to liveValue).
        static var testValue: Value { get }
    }
}

extension Dependency.Key where Value: Copyable {
    /// Default implementation returns the live value.
    ///
    /// Override this in your key type to provide test-specific
    /// implementations (mocks, stubs, spies).
    public static var testValue: Value { liveValue }
}

// WORKAROUND: Top-level typealias so macros can generate `__DependencyKey` conformances
// WHY: Swift macros cannot yet reference nested protocol types (`Dependency.Key`) in
//   generated conformance clauses
// WHEN TO REMOVE: When macro-generated code can reference nested protocols directly
// TRACKING: https://github.com/swiftlang/swift/issues/66450

/// Top-level alias for ``Dependency/Key`` enabling macro-generated conformances to name the protocol.
public typealias __DependencyKey = Dependency.Key
