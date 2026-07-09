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

private struct CounterKey: Dependency.Key {}

extension CounterKey {
    typealias Value = Int
    static var liveValue: Int { 0 }
    static var testValue: Int { 999 }
}

private struct StringKey: Dependency.Key {}

extension StringKey {
    typealias Value = String
    static var liveValue: String { "live" }
    static var testValue: String { "test" }
}

// MARK: - Tests

extension Dependency.Scope {
    @Suite("Dependency.Scope")
    struct Test {

        @Test
        func `default current returns liveValue`() {
            let value = Dependency.Scope.current[CounterKey.self]
            #expect(value == 0)
        }

        @Test
        func `with scope sets value`() {
            let result = Dependency.Scope.with { values in
                values[CounterKey.self] = 42
            } operation: {
                Dependency.Scope.current[CounterKey.self]
            }

            #expect(result == 42)
        }

        @Test
        func `nested scopes override correctly`() {
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

        @Test
        func `multiple keys in same scope`() {
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

        @Test
        func `async with scope works`() async {
            let result = await Dependency.Scope.with { values in
                values[CounterKey.self] = 50
            } operation: {
                await Task.yield()
                return Dependency.Scope.current[CounterKey.self]
            }

            #expect(result == 50)
        }

        @Test
        func `throwing operation propagates error`() {
            struct TestError: Swift.Error {}

            do {
                try Dependency.Scope.with { _ in
                } operation: {
                    throw TestError()
                }
                Issue.record("Expected error to be thrown")
            } catch {
                #expect(error is TestError)
            }
        }

        @Test
        func `async throwing operation propagates error`() async {
            struct TestError: Swift.Error {}

            do {
                try await Dependency.Scope.with { _ in
                } operation: {
                    throw TestError()
                }
                Issue.record("Expected error to be thrown")
            } catch {
                #expect(error is TestError)
            }
        }

        @Test
        func `scope inherits parent values`() {
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

        @Test
        func `value outside scope returns to default`() {
            Dependency.Scope.with { values in
                values[CounterKey.self] = 999
            } operation: {
                #expect(Dependency.Scope.current[CounterKey.self] == 999)
            }

            #expect(Dependency.Scope.current[CounterKey.self] == 0)
        }
    }
}
