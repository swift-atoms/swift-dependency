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

private struct NoTestValueKey: Dependency.Key {
    typealias Value = String
    static var liveValue: String { "default-live" }
}

// MARK: - Tests

@Suite("Dependency.Values")
struct DependencyValuesTests {

    @Test("empty values returns liveValue for unregistered key")
    func emptyReturnsLiveValue() {
        let values = Dependency.Values()
        #expect(values[CounterKey.self] == 0)
        #expect(values[StringKey.self] == "live")
    }

    @Test("subscript get/set works correctly")
    func subscriptGetSet() {
        var values = Dependency.Values()

        #expect(values[CounterKey.self] == 0)

        values[CounterKey.self] = 123
        #expect(values[CounterKey.self] == 123)

        values[CounterKey.self] = 456
        #expect(values[CounterKey.self] == 456)
    }

    @Test("multiple keys can be stored independently")
    func multipleKeysIndependent() {
        var values = Dependency.Values()

        values[CounterKey.self] = 100
        values[StringKey.self] = "custom"

        #expect(values[CounterKey.self] == 100)
        #expect(values[StringKey.self] == "custom")
    }

    @Test("isTestContext returns testValue when true")
    func testContextReturnsTestValue() {
        var values = Dependency.Values()
        values.isTestContext = true

        #expect(values[CounterKey.self] == 999)
        #expect(values[StringKey.self] == "test")
    }

    @Test("isTestContext false returns liveValue")
    func liveContextReturnsLiveValue() {
        var values = Dependency.Values()
        values.isTestContext = false

        #expect(values[CounterKey.self] == 0)
        #expect(values[StringKey.self] == "live")
    }

    @Test("forTesting factory sets isTestContext")
    func forTestingFactory() {
        let values = Dependency.Values.forTesting()

        #expect(values[CounterKey.self] == 999)
        #expect(values.isTestContext)
    }

    @Test("explicit value overrides test/live defaults")
    func explicitValueOverridesDefaults() {
        var values = Dependency.Values.forTesting()
        values[CounterKey.self] = 42

        #expect(values[CounterKey.self] == 42)
    }

    @Test("testValue defaults to liveValue when not overridden")
    func testValueDefaultsToLive() {
        var values = Dependency.Values.forTesting()

        #expect(values[NoTestValueKey.self] == "default-live")
    }
}
