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

    func testCanCreateInstanceFromWitnessTable() {
        let table = Combining<Int>.Table()
        table.register(Combining<Int>.sum)
        let combinable = FreeCombinable(context: 1)
        let otherCombinable = FreeCombinable(context: 3)
        let result = combinable.combine(otherCombinable)
        XCTAssertEqual(result.context as? Int, 4)
    }

    func testSelectStrategyWhenCreatingInstanceFromWitnessTable() {
        let table = Combining<Int>.Table()
        table.register(Combining<Int>.sum, label: "sum")
        table.register(Combining<Int>.prod, label: "prod")
        let combinable = FreeCombinable(context: 2, label: "prod")
        let otherCombinable = FreeCombinable(context: 3, label: "prod")
        let result = combinable.combine(otherCombinable)
        XCTAssertEqual(result.context as? Int, 6)
    }


    func testCanCreateInstanceFromWitnessTable_() {
        let table = Combining<Int>.Table()
        table.register(Combining<Int>.sum)
        let combinable = TypedFreeCombinable(context: 1)
        let otherCombinable = TypedFreeCombinable(context: 3)
        let result = combinable.combine(otherCombinable)
        XCTAssertEqual(result.context, 4)
    }
}

/// Creates a Combinable instance from any type provided there is a witness registered for that type in the corresponding witness table
struct FreeCombinable: Combinable {
    var context: Any
    var contextType: String
    var label: String?

    init<T>(context: T, label: String? = nil) {
        self.context = context
        self.contextType = "\(T.self)"
        self.label = label
    }

    func combine(_ other: FreeCombinable) -> FreeCombinable {
        let witness = CombinableWitness<Any>.Table().witness(for: contextType, label: label)!
        let newContext = witness.combine(context, other.context)
        return .init(context: newContext)
    }
}


struct TypedFreeCombinable<T>: Combinable {
    var context: T
    var contextType: String
    var label: String?

    init(context: T, label: String? = nil) {
        self.context = context
        self.contextType = "\(T.self)"
        self.label = label
    }

    func combine(_ other: TypedFreeCombinable<T>) -> TypedFreeCombinable<T> {
        let witness = CombinableWitness<T>.Table().witness(for: contextType, label: label)!
        let newContext = witness.combine(context, other.context)
        return .init(context: newContext as! T)
    }
}

