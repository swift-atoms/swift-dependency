import Dependency
import Testing

extension Dependency {
    @Suite
    struct `Keys distinguish dependencies` {
        enum First: Dependency.Key {}

        enum Second: Dependency.Key {}

        enum Default: Dependency.Key {}

        enum Aliased: __DependencyKey {}

        static func read<K: __DependencyKey>(
            _ key: K.Type,
            from values: Dependency.Values
        ) -> K.Value
        where K.Value: Copyable & Escapable {
            values[key]
        }

        static func acceptMarker<K: Witness.`Protocol`>(_: K.Type) {}
    }
}

extension Dependency.`Keys distinguish dependencies`.First {
    static var liveValue: Int { 1 }
    static var testValue: Int { 101 }
}

extension Dependency.`Keys distinguish dependencies`.Second {
    static var liveValue: Int { 1 }
    static var testValue: Int { 102 }
}

extension Dependency.`Keys distinguish dependencies`.Default {
    static var liveValue: String { "default" }
}

extension Dependency.`Keys distinguish dependencies`.Aliased {
    static var liveValue: String { "aliased" }
}

extension Dependency.`Keys distinguish dependencies` {
    @Test
    func `Distinct keys with the same value type retain independent overrides`() {
        var values = Dependency.Values()
        #expect(values[Self.First.self] == values[Self.Second.self])

        values[Self.First.self] = 42
        #expect(values[Self.Second.self] == 1)
        values[Self.Second.self] = 43
        #expect(values[Self.First.self] == 42)
        #expect(values[Self.Second.self] == 43)
    }

    @Test
    func `Each key selects its own test default`() {
        let values = Dependency.Values.forTesting()

        #expect(values[Self.First.self] == 101)
        #expect(values[Self.Second.self] == 102)
    }

    @Test
    func `Keys without a test default fall back to their live value`() {
        let live = Dependency.Values()
        let testing = Dependency.Values.forTesting()

        #expect(live[Self.Default.self] == "default")
        #expect(testing[Self.Default.self] == live[Self.Default.self])
    }

    @Test
    func `Both key spellings share storage and inherit the Witness marker`() {
        Self.acceptMarker(Self.First.self)
        Self.acceptMarker(Self.Aliased.self)
        var values = Dependency.Values()
        values[Self.First.self] = 42
        values[Self.Aliased.self] = "override"

        #expect(Self.read(Self.First.self, from: values) == 42)
        #expect(Self.read(Self.Aliased.self, from: values) == "override")
    }
}
