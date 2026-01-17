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

import Testing
@testable import Dependency_Primitives

// MARK: - Test Fixtures

private struct CounterKey: Dependency.Key {
    typealias Value = Int
    static var liveValue: Int { 0 }
    static var testValue: Int { 999 }
}

private struct StringKey: Dependency.Key {
    typealias Value = String
    static var liveValue: String { "live" }
    static var testValue: String { "test" }
}

// MARK: - Tests

@Suite("Dependency.Scope")
struct DependencyScopeTests {

    @Test("default current returns liveValue")
    func defaultCurrentReturnsLiveValue() {
        let value = Dependency.Scope.current[CounterKey.self]
        #expect(value == 0)
    }

    @Test("with scope sets value")
    func withScopeSetsValue() {
        let result = Dependency.Scope.with { values in
            values[CounterKey.self] = 42
        } operation: {
            Dependency.Scope.current[CounterKey.self]
        }

        #expect(result == 42)
    }

    @Test("nested scopes override correctly")
    func nestedScopesOverride() {
        var values: [Int] = []

        Dependency.Scope.with { v in
            v[CounterKey.self] = 1
        } operation: {
            values.append(Dependency.Scope.current[CounterKey.self])

            Dependency.Scope.with { v in
                v[CounterKey.self] = 2
            } operation: {
                values.append(Dependency.Scope.current[CounterKey.self])
            }

            values.append(Dependency.Scope.current[CounterKey.self])
        }

        #expect(values == [1, 2, 1])
    }

    @Test("multiple keys in same scope")
    func multipleKeysInScope() {
        let result = Dependency.Scope.with { values in
            values[CounterKey.self] = 100
            values[StringKey.self] = "custom"
        } operation: {
            (
                counter: Dependency.Scope.current[CounterKey.self],
                string: Dependency.Scope.current[StringKey.self]
            )
        }

        #expect(result.counter == 100)
        #expect(result.string == "custom")
    }

    @Test("async with scope works")
    func asyncWithScopeWorks() async {
        let result = await Dependency.Scope.with { values in
            values[CounterKey.self] = 50
        } operation: {
            await Task.yield()
            return Dependency.Scope.current[CounterKey.self]
        }

        #expect(result == 50)
    }

    @Test("throwing operation propagates error")
    func throwingOperationPropagatesError() {
        struct TestError: Error {}

        do {
            try Dependency.Scope.with { _ in } operation: {
                throw TestError()
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is TestError)
        }
    }

    @Test("async throwing operation propagates error")
    func asyncThrowingOperationPropagatesError() async {
        struct TestError: Error {}

        do {
            try await Dependency.Scope.with { _ in } operation: {
                throw TestError()
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is TestError)
        }
    }

    @Test("scope inherits parent values")
    func scopeInheritsParentValues() {
        let result = Dependency.Scope.with { values in
            values[CounterKey.self] = 10
            values[StringKey.self] = "parent"
        } operation: {
            Dependency.Scope.with { values in
                values[CounterKey.self] = 20
                // StringKey not overridden
            } operation: {
                (
                    counter: Dependency.Scope.current[CounterKey.self],
                    string: Dependency.Scope.current[StringKey.self]
                )
            }
        }

        #expect(result.counter == 20)
        #expect(result.string == "parent")
    }

    @Test("value outside scope returns to default")
    func valueOutsideScopeReturnsToDefault() {
        Dependency.Scope.with { values in
            values[CounterKey.self] = 999
        } operation: {
            #expect(Dependency.Scope.current[CounterKey.self] == 999)
        }

        #expect(Dependency.Scope.current[CounterKey.self] == 0)
    }
}
