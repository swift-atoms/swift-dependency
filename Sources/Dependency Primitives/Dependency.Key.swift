public import Witness_Primitives

extension Dependency {

    public protocol Key: Sendable, Witness.`Protocol` {

        associatedtype Value: ~Copyable & Sendable

        static var liveValue: Value { get }

        static var testValue: Value { get }
    }
}

extension Dependency.Key where Value: Copyable {

    public static var testValue: Value { liveValue }
}

public typealias __DependencyKey = Dependency.Key
