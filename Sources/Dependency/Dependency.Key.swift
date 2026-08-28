public import Witness

extension Dependency {

    public protocol Key: Sendable, Witness.`Protocol` {

        associatedtype Value: ~Copyable & ~Escapable & Sendable

        static var liveValue: Value { get }

        static var testValue: Value { get }
    }
}

extension Dependency.Key where Value: Copyable & Escapable {

    public static var testValue: Value { liveValue }
}

public typealias __DependencyKey = Dependency.Key
