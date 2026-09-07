import Dependency
import Testing

extension Dependency {
    @Suite
    struct `Scopes isolate dependency bindings` {
        enum Number: Dependency.Key {
            static var liveValue: Int { 0 }
            static var testValue: Int { 100 }
        }

        enum Text: Dependency.Key {
            static var liveValue: String { "live" }
            static var testValue: String { "test" }
        }

        enum Failure: Swift.Error, Equatable {
            case refused(Int)
        }

        struct Snapshot: Sendable, Equatable {
            let number: Int
            let text: String
            let testing: Bool
        }

        actor Rendezvous {
            let participants: Int
            private var arrivals = 0
            private var waiters: [CheckedContinuation<Void, Never>] = []

            init(participants: Int) {
                self.participants = participants
            }

            func arrive() async {
                arrivals += 1
                if arrivals == participants {
                    let ready = waiters
                    waiters.removeAll()
                    for waiter in ready { waiter.resume() }
                } else {
                    await withCheckedContinuation { waiters.append($0) }
                }
            }
        }

        static func snapshot() -> Snapshot {
            let values = Dependency.Scope.current
            return Snapshot(
                number: values[Number.self],
                text: values[Text.self],
                testing: values.isTestContext
            )
        }

        static func snapshotAfterYield() async -> Snapshot {
            await Task.yield()
            return snapshot()
        }

        static let live = Snapshot(number: 0, text: "live", testing: false)
    }
}

extension Dependency.`Scopes isolate dependency bindings` {
    @Test
    func `Candidate values remain separate until the operation starts`() {
        let result = Dependency.Scope.with { values in
            values[Self.Number.self] = 42
            values.isTestContext = true
            #expect(values[Self.Number.self] == 42)
            #expect(Self.snapshot() == Self.live)
        } operation: {
            Self.snapshot()
        }

        #expect(result == Self.Snapshot(number: 42, text: "test", testing: true))
        #expect(Self.snapshot() == Self.live)
    }

    @Test
    func `Nested scopes inherit untouched bindings and restore their parent`() {
        Dependency.Scope.with { values in
            values[Self.Number.self] = 1
            values[Self.Text.self] = "parent"
        } operation: {
            let nested = Dependency.Scope.with { values in
                values[Self.Number.self] = 2
                values.isTestContext = true
            } operation: {
                Self.snapshot()
            }

            #expect(nested == Self.Snapshot(number: 2, text: "parent", testing: true))
            #expect(Self.snapshot() == Self.Snapshot(number: 1, text: "parent", testing: false))
        }

        #expect(Self.snapshot() == Self.live)
    }

    @Test
    func `Current values can be retained after their scope ends`() {
        let snapshot = Dependency.Scope.with { values in
            values[Self.Number.self] = 42
            values.isTestContext = true
        } operation: {
            Dependency.Scope.current
        }

        #expect(snapshot[Self.Number.self] == 42)
        #expect(snapshot[Self.Text.self] == "test")
        #expect(snapshot.isTestContext)
        #expect(Self.snapshot() == Self.live)
    }

    @Test
    func `Mutating a current snapshot leaves the active binding intact`() {
        Dependency.Scope.with { values in
            values[Self.Number.self] = 42
        } operation: {
            var snapshot = Dependency.Scope.current
            snapshot[Self.Number.self] = 43
            snapshot.isTestContext = true

            #expect(snapshot[Self.Number.self] == 43)
            #expect(snapshot[Self.Text.self] == "test")
            #expect(Self.snapshot() == Self.Snapshot(number: 42, text: "live", testing: false))
        }

        #expect(Self.snapshot() == Self.live)
    }

    @Test(arguments: [false, true])
    func `Synchronous typed results and failures restore the parent scope`(_ fails: Bool) {
        Dependency.Scope.with { values in
            values[Self.Number.self] = 1
        } operation: {
            let outcome: Result<Int, Self.Failure>
            do throws(Self.Failure) {
                let result = try Dependency.Scope.with { values in
                    values[Self.Number.self] = 2
                    values.isTestContext = true
                } operation: { () throws(Self.Failure) -> Int in
                    #expect(Self.snapshot() == Self.Snapshot(number: 2, text: "test", testing: true))
                    if fails { throw .refused(7) }
                    return 42
                }
                outcome = .success(result)
            } catch {
                outcome = .failure(error)
            }

            #expect(outcome == (fails ? .failure(.refused(7)) : .success(42)))
            #expect(Self.snapshot() == Self.Snapshot(number: 1, text: "live", testing: false))
        }

        #expect(Self.snapshot() == Self.live)
    }

    @Test(arguments: [false, true])
    func `Asynchronous typed results and failures restore the parent after suspension`(_ fails: Bool) async {
        await Dependency.Scope.with { values in
            values[Self.Number.self] = 1
        } operation: {
            let outcome: Result<Int, Self.Failure>
            do throws(Self.Failure) {
                let result = try await Dependency.Scope.with { values in
                    values[Self.Number.self] = 2
                    values.isTestContext = true
                } operation: { () async throws(Self.Failure) -> Int in
                    await Task.yield()
                    #expect(Self.snapshot() == Self.Snapshot(number: 2, text: "test", testing: true))
                    if fails { throw .refused(7) }
                    return 42
                }
                outcome = .success(result)
            } catch {
                outcome = .failure(error)
            }

            #expect(outcome == (fails ? .failure(.refused(7)) : .success(42)))
            #expect(Self.snapshot() == Self.Snapshot(number: 1, text: "live", testing: false))
        }

        #expect(Self.snapshot() == Self.live)
    }

    @Test
    func `Structured child tasks inherit bindings across suspension`() async {
        await Dependency.Scope.with { values in
            values[Self.Number.self] = 42
            values.isTestContext = true
        } operation: {
            async let first = Self.snapshotAfterYield()
            async let second = Self.snapshotAfterYield()
            let children = await (first, second)
            let expected = Self.Snapshot(number: 42, text: "test", testing: true)

            #expect(children.0 == expected)
            #expect(children.1 == expected)
            #expect(Self.snapshot() == expected)
        }

        #expect(Self.snapshot() == Self.live)
    }

    @Test
    func `Detached tasks start with defaults even inside a testing scope`() async {
        await Dependency.Scope.with { values in
            values[Self.Number.self] = 42
            values.isTestContext = true
        } operation: {
            let detached = Task.detached { await Self.snapshotAfterYield() }

            #expect(await detached.value == Self.live)
            #expect(Self.snapshot() == Self.Snapshot(number: 42, text: "test", testing: true))
        }

        #expect(Self.snapshot() == Self.live)
    }

    @Test
    func `Concurrent child overrides stay isolated while all scopes are active`() async {
        let rendezvous = Self.Rendezvous(participants: 8)
        await Dependency.Scope.with { values in
            values[Self.Number.self] = 1000
            values[Self.Text.self] = "parent"
        } operation: {
            let snapshots = await withTaskGroup(of: Self.Snapshot.self, returning: [Self.Snapshot].self) { group in
                for number in 1...8 {
                    group.addTask {
                        await Dependency.Scope.with { values in
                            values[Self.Number.self] = number
                            values.isTestContext = number.isMultiple(of: 2)
                        } operation: {
                            await rendezvous.arrive()
                            let first = Self.snapshot()
                            await Task.yield()
                            #expect(Self.snapshot() == first)
                            return first
                        }
                    }
                }
                var snapshots: [Self.Snapshot] = []
                for await snapshot in group { snapshots.append(snapshot) }
                return snapshots
            }

            let expected = (1...8).map {
                Self.Snapshot(number: $0, text: "parent", testing: $0.isMultiple(of: 2))
            }
            #expect(snapshots.sorted { $0.number < $1.number } == expected)
            #expect(Self.snapshot() == Self.Snapshot(number: 1000, text: "parent", testing: false))
        }

        #expect(Self.snapshot() == Self.live)
    }
}
