extension Dependency {

    public struct Scope: Sendable {

        public var values: Values
    }
}

extension Dependency.Scope {

    @TaskLocal
    private static var _current: Dependency.Scope = Self(values: Dependency.Values())
}

extension Dependency.Scope {

    public static var current: Dependency.Values {
        _current.values
    }
}

extension Dependency.Scope {

    public static func with<T, E: Swift.Error>(
        _ modify: (inout Dependency.Values) -> Void,
        operation: () throws(E) -> T
    ) throws(E) -> T {
        var scope = _current
        modify(&scope.values)

        let result: Result<T, E> = $_current.withValue(
            scope,
            operation: {
                do throws(E) {
                    return .success(try operation())
                } catch {
                    return .failure(error)
                }
            }
        )
        return try result.get()
    }

    public static func with<T>(
        _ modify: (inout Dependency.Values) -> Void,
        operation: () -> T
    ) -> T {
        var scope = _current
        modify(&scope.values)
        return $_current.withValue(scope, operation: operation)
    }
}

extension Dependency.Scope {

    nonisolated(nonsending)
        public static func with<T, E: Swift.Error>(
            _ modify: (inout Dependency.Values) -> Void,
            operation: nonisolated(nonsending) () async throws(E) -> T
        ) async throws(E) -> T
    {
        var scope = _current
        modify(&scope.values)

        let result: Result<T, E> = await $_current.withValue(
            scope,
            operation: {
                do throws(E) {
                    return .success(try await operation())
                } catch {
                    return .failure(error)
                }
            }
        )
        return try result.get()
    }

}
