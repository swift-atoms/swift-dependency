extension Dependency {

    public struct Values: Sendable {

        private var storage: [ObjectIdentifier: any Sendable] = [:]
        private var _isTestContext: Bool = false

        public init() {}
    }
}

extension Dependency.Values {

    public var isTestContext: Bool {
        get { _isTestContext }
        set { _isTestContext = newValue }
    }

    public subscript<K: Dependency.Key>(key: K.Type) -> K.Value
    where K.Value: Copyable & Escapable {
        get {
            if let stored = storage[ObjectIdentifier(key)], let value = stored as? K.Value {
                return value
            }
            return _isTestContext ? K.testValue : K.liveValue
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }
}

extension Dependency.Values {

    public static func forTesting() -> Self {
        var values = Self()
        values._isTestContext = true
        return values
    }
}
