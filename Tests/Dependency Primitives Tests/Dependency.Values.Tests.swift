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

private struct NoTestValueKey: Dependency.Key {}

extension NoTestValueKey {
    typealias Value = String
    static var liveValue: String { "default-live" }
}

// MARK: - Tests

@Suite("Dependency.Values")
struct DependencyValuesTests {

    @Test
    func `empty values returns liveValue for unregistered key`() {
        let values = Dependency.Values()
        #expect(values[CounterKey.self] == 0)
        #expect(values[StringKey.self] == "live")
    }

    @Test
    func `subscript get/set works correctly`() {
        var values = Dependency.Values()

        #expect(values[CounterKey.self] == 0)

        values[CounterKey.self] = 123
        #expect(values[CounterKey.self] == 123)

        values[CounterKey.self] = 456
        #expect(values[CounterKey.self] == 456)
    }

    @Test
    func `multiple keys can be stored independently`() {
        var values = Dependency.Values()

        values[CounterKey.self] = 100
        values[StringKey.self] = "custom"

        #expect(values[CounterKey.self] == 100)
        #expect(values[StringKey.self] == "custom")
    }

    @Test
    func `isTestContext returns testValue when true`() {
        var values = Dependency.Values()
        values.isTestContext = true

        #expect(values[CounterKey.self] == 999)
        #expect(values[StringKey.self] == "test")
    }

    @Test
    func `isTestContext false returns liveValue`() {
        var values = Dependency.Values()
        values.isTestContext = false

        #expect(values[CounterKey.self] == 0)
        #expect(values[StringKey.self] == "live")
    }

    @Test
    func `forTesting factory sets isTestContext`() {
        let values = Dependency.Values.forTesting()

        #expect(values[CounterKey.self] == 999)
        #expect(values.isTestContext)
    }

    @Test
    func `explicit value overrides test/live defaults`() {
        var values = Dependency.Values.forTesting()
        values[CounterKey.self] = 42

        #expect(values[CounterKey.self] == 42)
    }

    @Test
    func `testValue defaults to liveValue when not overridden`() {
        var values = Dependency.Values.forTesting()

        #expect(values[NoTestValueKey.self] == "default-live")
    }
}
