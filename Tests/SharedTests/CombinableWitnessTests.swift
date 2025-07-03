//
//  CombinableWitnessTests.swift
//  Witness
//
//  Created by Daniel Cardona on 30/06/25.
//

import XCTest
@testable import Witness
@testable import Shared

final class CombinableWitnessTests: XCTestCase {

    class override func setUp() {
        super.setUp()
        Combining<Int>.sum.register(strategy: "sum")
        Combining<Int>.prod.register(strategy: "prod")
    }

    func testCanCreateInstanceFromWitnessTable() {
        let combinable = Combining<Int>.Synthesized(context: 1, strategy: "sum")
        let otherCombinable = Combining<Int>.Synthesized(context: 3, strategy: "sum")
        let result = combinable.combine(otherCombinable)
        XCTAssertEqual(result.context as? Int, 4)
    }

    func testSelectStrategyWhenCreatingInstanceFromWitnessTable() {
        let combinable = Combining<Int>.Synthesized(context: 2, strategy: "prod")
        let otherCombinable = Combining<Int>.Synthesized(context: 3, strategy: "prod")
        let result = combinable.combine(otherCombinable)
        XCTAssertEqual(result.context as? Int, 6)
    }
}

