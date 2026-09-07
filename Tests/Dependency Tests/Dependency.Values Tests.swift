import Dependency
import Testing

extension Dependency {
    @Suite
    struct `Values preserve explicit overrides` {
        enum Number: Dependency.Key {
            static var liveValue: Int { 42 }
            static var testValue: Int { 999 }
        }

        enum Text: Dependency.Key {
            static var liveValue: String { "live" }
            static var testValue: String { "test" }
        }

        enum OptionalNumber: Dependency.Key {
            static var liveValue: Int? { 42 }
            static var testValue: Int? { 999 }
        }

        enum Numbers: Dependency.Key {
            static var liveValue: [Int] { [] }
        }

        final class Client: Sendable {
            let value: Int

            init(_ value: Int) { self.value = value }
        }

        enum Service: Dependency.Key {
            static var liveValue: Client { Client(0) }
        }
    }
}

extension Dependency.`Values preserve explicit overrides` {
    @Test
    func `Empty values use live defaults and the testing factory uses test defaults`() {
        let live = Dependency.Values()
        let testing = Dependency.Values.forTesting()

        #expect(!live.isTestContext)
        #expect(live[Self.Number.self] == 42)
        #expect(live[Self.Text.self] == "live")
        #expect(testing.isTestContext)
        #expect(testing[Self.Number.self] == 999)
        #expect(testing[Self.Text.self] == "test")
    }

    @Test
    func `Changing context changes defaults while retaining explicit overrides`() {
        var values = Dependency.Values()
        values[Self.Number.self] = 7
        values.isTestContext = true

        #expect(values[Self.Number.self] == 7)
        #expect(values[Self.Text.self] == "test")

        values[Self.Number.self] = 8
        values.isTestContext = false
        #expect(values[Self.Number.self] == 8)
        #expect(values[Self.Text.self] == "live")
    }

    @Test(arguments: [false, true])
    func `An explicit nil overrides a nonnil default in either context`(_ testing: Bool) {
        var values = Dependency.Values()
        values.isTestContext = testing
        #expect(values[Self.OptionalNumber.self] == (testing ? 999 : 42))

        values[Self.OptionalNumber.self] = nil
        #expect(values[Self.OptionalNumber.self] == nil)
        values.isTestContext.toggle()
        #expect(values[Self.OptionalNumber.self] == nil)

        values[Self.OptionalNumber.self] = 7
        #expect(values[Self.OptionalNumber.self] == 7)
    }

    @Test
    func `Copies keep independent stored collections and context flags`() {
        var original = Dependency.Values()
        original[Self.Numbers.self] = [1, 2]
        var copy = original

        copy[Self.Numbers.self].append(3)
        copy.isTestContext = true
        original[Self.Numbers.self].append(4)

        #expect(original[Self.Numbers.self] == [1, 2, 4])
        #expect(copy[Self.Numbers.self] == [1, 2, 3])
        #expect(!original.isTestContext)
        #expect(copy.isTestContext)
        #expect(original[Self.Text.self] == "live")
        #expect(copy[Self.Text.self] == "test")
    }

    @Test
    func `A retained snapshot preserves values after the original changes`() {
        var original = Dependency.Values.forTesting()
        original[Self.Number.self] = 7
        let snapshot = original

        original[Self.Number.self] = 8
        original.isTestContext = false

        #expect(snapshot[Self.Number.self] == 7)
        #expect(snapshot[Self.Text.self] == "test")
        #expect(original[Self.Number.self] == 8)
        #expect(original[Self.Text.self] == "live")
    }

    @Test
    func `Copying values preserves an explicitly stored reference identity`() {
        let client = Self.Client(42)
        var original = Dependency.Values()
        original[Self.Service.self] = client
        var copy = original

        #expect(copy[Self.Service.self] === client)
        copy[Self.Service.self] = Self.Client(43)

        #expect(original[Self.Service.self] === client)
        #expect(copy[Self.Service.self] !== client)
        #expect(original[Self.Service.self].value == 42)
        #expect(copy[Self.Service.self].value == 43)
    }
}
