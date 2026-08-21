import Testing

@testable import Dependency_Primitives

private struct IntKey: Dependency.Key {}

extension IntKey {
    typealias Value = Int
    static var liveValue: Int { 42 }
    static var testValue: Int { 999 }
}

private struct StringKey: Dependency.Key {}

extension StringKey {
    typealias Value = String
    static var liveValue: String { "live" }
    static var testValue: String { "test" }
}

private struct DefaultTestValueKey: Dependency.Key {}

extension DefaultTestValueKey {
    typealias Value = String
    static var liveValue: String { "only-live" }

}

@Suite struct `Dependency.Key Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Dependency.Key Tests`.Unit {
    @Test
    func `liveValue is accessible`() {
        #expect(IntKey.liveValue == 42)
        #expect(StringKey.liveValue == "live")
    }

    @Test
    func `testValue is accessible`() {
        #expect(IntKey.testValue == 999)
        #expect(StringKey.testValue == "test")
    }

    @Test
    func `testValue defaults to liveValue when not overridden`() {
        #expect(DefaultTestValueKey.testValue == "only-live")
        #expect(DefaultTestValueKey.testValue == DefaultTestValueKey.liveValue)
    }
}
