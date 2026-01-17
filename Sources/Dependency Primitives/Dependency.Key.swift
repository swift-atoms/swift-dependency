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
    public protocol Key: Sendable {
        /// The value type this key provides.
        associatedtype Value: Sendable

        /// The default value for production use.
        static var liveValue: Value { get }

        /// The default value for testing (defaults to liveValue).
        static var testValue: Value { get }
    }
}

extension Dependency.Key {
    /// Default implementation returns the live value.
    ///
    /// Override this in your key type to provide test-specific
    /// implementations (mocks, stubs, spies).
    public static var testValue: Value { liveValue }
}

/// Workaround for macro conformance limitations.
///
/// Use `Dependency.Key` in all other contexts.
public typealias __DependencyKey = Dependency.Key
