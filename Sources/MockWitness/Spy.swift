
import Foundation
import Matchers

/// A Spy is a test-specific object that wraps a function, recording its invocations
/// and providing a stubbed return value.
public final class Spy<Input, Output>: AnySpy {
    /// An array storing the arguments of every call made to this spy.
    public private(set) var invocations: [Input] = []

    // The list of conditional stubs.
    private var conditionalStubs: [ConditionalStub<Input, Output>] = []

    // A default stub to use if no conditional stubs match.
    private var defaultStub: ((Input) -> Output)?

    public init(defaultStub: ((Input) -> Output)? = nil) {
        self.defaultStub = defaultStub
    }

    /// The function that replaces the real implementation in the witness.
    /// When called, it records the arguments and returns the stubbed value.
    public func call(_ input: Input) -> Output {
        invocations.append(input)

        // Find the first conditional stub that matches the input.
        if let matchingStub = conditionalStubs.first(where: { $0.matches(args: input) }) {
            return matchingStub.stub(input)
        }

        // If none match, use the default.
        return defaultStub!(input)
    }

    // MARK: - Stubbing

    /// A convenience method to easily stub a default return value.
    public func willReturn(_ value: Output) {
        self.defaultStub = { _ in value }
    }

    /// A builder for creating conditional stubs.
    public func when(calledWith matchers: ArgMatcherProtocol...) -> StubBuilder {
        return StubBuilder(spy: self, matchers: matchers)
    }

    // This is an internal helper to add a conditional stub.
    fileprivate func addConditionalStub(_ stub: ConditionalStub<Input, Output>) {
        // Insert at the beginning so the most recently defined stubs are checked first.
        conditionalStubs.insert(stub, at: 0)
    }

    // MARK: - AnySpy Conformance

    public var erasedInvocations: [Any] {
        return invocations
    }
}

// MARK: - StubBuilder

public extension Spy {
    /// A helper class to create the fluent `when(...).willReturn(...)` API.
    class StubBuilder {
        private let spy: Spy
        private let matchers: [ArgMatcherProtocol]

        init(spy: Spy, matchers: [ArgMatcherProtocol]) {
            self.spy = spy
            self.matchers = matchers
        }

        public func willReturn(_ value: Output) {
            let newStub = ConditionalStub<Input,Output>(matchers: matchers, stub: { _ in value })
            spy.addConditionalStub(newStub)
        }
    }
}

// MARK: - ConditionalStub

private struct ConditionalStub<Input, Output> {
    let matchers: [ArgMatcherProtocol]
    let stub: (Input) -> Output

    func matches(args: Input) -> Bool {
        let arguments = Mirror(reflecting: args).children.map { $0.value }

        if arguments.isEmpty && Mirror(reflecting: args).children.isEmpty && !(args is Void) {
            guard matchers.count == 1 else { return false }
            return matchers[0].matcher.matches(argument: args)
        }

        guard arguments.count == matchers.count else { return false }

        for (index, matcher) in matchers.enumerated() {
            if !matcher.matcher.matches(argument: arguments[index]) {
                return false
            }
        }
        return true
    }
}

/// A type-erased spy protocol to be used in the `Mock` container.
public protocol AnySpy {
    var erasedInvocations: [Any] { get }
}
