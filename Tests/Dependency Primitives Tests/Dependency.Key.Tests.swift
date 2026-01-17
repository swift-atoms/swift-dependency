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

private struct IntKey: Dependency.Key {
    typealias Value = Int
    static var liveValue: Int { 42 }
    static var testValue: Int { 999 }
}

private struct StringKey: Dependency.Key {
    typealias Value = String
    static var liveValue: String { "live" }
    static var testValue: String { "test" }
}

private struct DefaultTestValueKey: Dependency.Key {
    typealias Value = String
    static var liveValue: String { "only-live" }
    // testValue defaults to liveValue
}

// MARK: - Tests

@Suite("Dependency.Key")
struct DependencyKeyTests {

    @Test("liveValue is accessible")
    func liveValueAccessible() {
        #expect(IntKey.liveValue == 42)
        #expect(StringKey.liveValue == "live")
    }

    @Test("testValue is accessible")
    func testValueAccessible() {
        #expect(IntKey.testValue == 999)
        #expect(StringKey.testValue == "test")
    }

    @Test("testValue defaults to liveValue when not overridden")
    func testValueDefaultsToLive() {
        #expect(DefaultTestValueKey.testValue == "only-live")
        #expect(DefaultTestValueKey.testValue == DefaultTestValueKey.liveValue)
    }
}
