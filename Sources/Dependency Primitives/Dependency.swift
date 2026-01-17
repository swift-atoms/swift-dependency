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

/// Namespace for dependency injection primitives.
///
/// This namespace contains the core building blocks for type-safe dependency
/// injection with live/test variants and task-local scoping.
///
/// ## Core Components
///
/// - ``Dependency/Key``: Protocol for defining dependency keys with live/test values
/// - ``Dependency/Values``: Type-safe heterogeneous storage for dependencies
/// - ``Dependency/Scope``: Task-local scoping for dependency resolution
///
/// ## Example
///
/// ```swift
/// // Define a dependency key
/// struct APIClient: Dependency.Key {
///     typealias Value = APIClientImpl
///     static var liveValue: Value { .production }
///     static var testValue: Value { .mock }
/// }
///
/// // Use in a scoped context
/// Dependency.Scope.with { values in
///     values[APIClient.self] = .staging
/// } operation: {
///     let client = Dependency.Scope.current[APIClient.self]
///     // Uses .staging
/// }
/// ```
public enum Dependency {}
