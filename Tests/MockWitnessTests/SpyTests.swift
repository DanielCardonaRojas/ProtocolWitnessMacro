
import XCTest
@testable import MockWitness
import Matchers

final class SpyTests: XCTestCase {

    // MARK: - Basic Stubbing and Invocation Recording

    func test_spy_recordsInvocations_andReturnsStubbedValue() {
        let spy = Spy<String, Int>()
        spy.willReturn(10)

        XCTAssertEqual(spy.call("hello"), 10)
        XCTAssertEqual(spy.call("world"), 10)

        XCTAssertEqual(spy.invocations.count, 2)
        XCTAssertEqual(spy.invocations[0], "hello")
        XCTAssertEqual(spy.invocations[1], "world")
    }

    func test_spy_withVoidInput_recordsInvocations_andReturnsStubbedValue() {
        let spy = Spy<Void, String>()
        spy.willReturn("success")

        XCTAssertEqual(spy.call(()), "success")
        XCTAssertEqual(spy.call(()), "success")

        XCTAssertEqual(spy.invocations.count, 2)
    }

    func test_spy_withVoidOutput_recordsInvocations() {
        let spy = Spy<String, Void>()
        spy.willReturn(())

        spy.call("action1")
        spy.call("action2")

        XCTAssertEqual(spy.invocations.count, 2)
        XCTAssertEqual(spy.invocations[0], "action1")
        XCTAssertEqual(spy.invocations[1], "action2")
    }

//    // MARK: - Conditional Stubbing

    func test_spy_conditionalStubbing_matchesCorrectly() {
        let spy = Spy<String, Int>()
        spy.willReturn(99) // Default stub

        spy.when(calledWith: ArgMatcher<String>.equals("apple")).willReturn(1)
        spy.when(calledWith: ArgMatcher<String>.equals("banana")).willReturn(2)

        XCTAssertEqual(spy.call("apple"), 1, "Should match 'apple' specific stub")
        XCTAssertEqual(spy.call("banana"), 2, "Should match 'banana' specific stub")

        XCTAssertEqual(spy.invocations.count, 2)
        XCTAssertEqual(spy.invocations[0], "apple")
        XCTAssertEqual(spy.invocations[1], "banana")
    }

    func test_spy_conditionalStubbing_withMultipleArguments() {
        let spy = Spy<(String, Int), String>()
        spy.willReturn("default")

        spy.when(calledWith: ArgMatcher<String>.equals("itemA"), ArgMatcher<Int>.equals(10)).willReturn("A10")
        spy.when(calledWith: ArgMatcher<String>.any(), ArgMatcher<Int>.lessThan(5)).willReturn("any_lt5")
        spy.when(calledWith: ArgMatcher<String>.equals("itemB"), ArgMatcher<Int>.any()).willReturn("B_any")

        XCTAssertEqual(spy.call(("itemA", 10)), "A10", "Should match itemA and 10")
        XCTAssertEqual(spy.call(("itemC", 3)), "any_lt5", "Should match any and less than 5")
        XCTAssertEqual(spy.call(("itemB", 20)), "B_any", "Should match itemB and any")
        XCTAssertEqual(spy.call(("itemX", 100)), "default", "Should fall back to default")

        XCTAssertEqual(spy.invocations.count, 4)
    }

    func test_spy_conditionalStubbing_orderMatters() {
        let spy = Spy<Int, String>()
        spy.willReturn("default")

        spy.when(calledWith: ArgMatcher<Int>.any()).willReturn("any_first")
        spy.when(calledWith: ArgMatcher<Int>.equals(5)).willReturn("five_specific") // This is added *after* any()

        XCTAssertEqual(spy.call(5), "five_specific", "Specific stub should take precedence if added last")
        XCTAssertEqual(spy.call(10), "any_first", "Any stub should still work for other values")
    }

    func test_spy_noMatchingConditionalStub_usesDefault() {
        let spy = Spy<String, Bool>()
        spy.willReturn(false)

        spy.when(calledWith: ArgMatcher<String>.equals("match")).willReturn(true)

        XCTAssertTrue(spy.call("match"))
        XCTAssertFalse(spy.call("no_match"))
        XCTAssertEqual(spy.invocations.count, 2)
    }

    func test_spy_initialDefaultStub_isUsedWhenNoConditionalStubs() {
        let spy = Spy<Int, String>(defaultStub: { _ in "initial default" })
        XCTAssertEqual(spy.call(1), "initial default")
        XCTAssertEqual(spy.invocations.count, 1)
    }

    func test_spy_overwritingDefaultStub() {
        let spy = Spy<Int, String>(defaultStub: { _ in "initial default" })
        spy.willReturn("new default")
        XCTAssertEqual(spy.call(1), "new default")
        XCTAssertEqual(spy.invocations.count, 1)
    }
}
