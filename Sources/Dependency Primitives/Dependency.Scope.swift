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
    /// Task-local scoping for dependency resolution.
    ///
    /// `Scope` provides scoped dependency registration via Task-local storage.
    /// Use ``with(_:operation:)-3hkzn`` to register dependencies for a scope:
    ///
    /// ```swift
    /// try await Dependency.Scope.with { values in
    ///     values[APIClient.self] = .live
    /// } operation: {
    ///     // APIClient.self resolves to .live here
    ///     let client = Dependency.Scope.current[APIClient.self]
    /// }
    /// ```
    ///
    /// ## Nested Scopes
    ///
    /// Dependencies can be overridden in nested scopes:
    ///
    /// ```swift
    /// Dependency.Scope.with { values in
    ///     values[Logger.self] = .file
    /// } operation: {
    ///     // Logger is .file here
    ///     Dependency.Scope.with { values in
    ///         values[Logger.self] = .console
    ///     } operation: {
    ///         // Logger is .console here
    ///     }
    ///     // Logger is .file here again
    /// }
    /// ```
    ///
    /// ## Accessing Dependencies
    ///
    /// Within a scope, access the current dependencies:
    ///
    /// ```swift
    /// let client = Dependency.Scope.current[APIClient.self]
    /// ```
    public struct Scope: Sendable {
        /// Task-local storage for the current scope.
        @TaskLocal
        private static var _current: Scope = Scope(values: Values())

        /// The registered values in this scope.
        public var values: Values

        internal init(values: Values) {
            self.values = values
        }
    }
}

// MARK: - Current Access

extension Dependency.Scope {
    /// The current values for this task.
    ///
    /// Returns the values from the innermost ``with(_:operation:)-3hkzn`` scope,
    /// or the default values if not in a scope.
    public static var current: Dependency.Values {
        _current.values
    }
}

// MARK: - Scoped Registration (Synchronous)

extension Dependency.Scope {
    /// Executes a closure with modified values.
    ///
    /// This is the primary way to establish dependency scope.
    /// Values registered here are visible to all code executed within
    /// the operation closure.
    ///
    /// - Parameters:
    ///   - modify: A closure that modifies the values for the scope.
    ///   - operation: The operation to execute with the modified values.
    /// - Returns: The result of the operation.
    /// - Throws: The typed error from the operation.
    public static func with<T, E: Error>(
        _ modify: (inout Dependency.Values) -> Void,
        operation: () throws(E) -> T
    ) throws(E) -> T {
        var scope = _current
        modify(&scope.values)
        let result: Result<T, E> = $_current.withValue(scope) {
            do throws(E) {
                return .success(try operation())
            } catch {
                return .failure(error)
            }
        }
        return try result.get()
    }

    /// Executes a closure with modified values (non-throwing).
    ///
    /// - Parameters:
    ///   - modify: A closure that modifies the values for the scope.
    ///   - operation: The operation to execute with the modified values.
    /// - Returns: The result of the operation.
    public static func with<T>(
        _ modify: (inout Dependency.Values) -> Void,
        operation: () -> T
    ) -> T {
        var scope = _current
        modify(&scope.values)
        return $_current.withValue(scope, operation: operation)
    }
}

// MARK: - Scoped Registration (Asynchronous)

extension Dependency.Scope {
    /// Executes an async closure with modified values.
    ///
    /// This is the primary way to establish async dependency scope.
    /// Values registered here are visible to all code executed within
    /// the operation closure, including across await points.
    ///
    /// - Parameters:
    ///   - modify: A closure that modifies the values for the scope.
    ///   - operation: The async operation to execute with the modified values.
    /// - Returns: The result of the operation.
    /// - Throws: The typed error from the operation.
    public static func with<T, E: Error>(
        _ modify: (inout Dependency.Values) -> Void,
        operation: () async throws(E) -> T
    ) async throws(E) -> T {
        var scope = _current
        modify(&scope.values)
        let result: Result<T, E> = await $_current.withValue(scope) {
            do throws(E) {
                return .success(try await operation())
            } catch {
                return .failure(error)
            }
        }
        return try result.get()
    }

    /// Executes an async closure with modified values (non-throwing).
    ///
    /// - Parameters:
    ///   - modify: A closure that modifies the values for the scope.
    ///   - operation: The async operation to execute with the modified values.
    /// - Returns: The result of the operation.
    public static func with<T>(
        _ modify: (inout Dependency.Values) -> Void,
        operation: () async -> T
    ) async -> T {
        var scope = _current
        modify(&scope.values)
        return await $_current.withValue(scope, operation: operation)
    }
}
