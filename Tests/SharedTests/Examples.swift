//
//  Examples.swift
//  Witness
//
//  Created by Daniel Cardona on 2/07/25.
//
import Witness
import Shared

@Witnessed([.utilities, .conformanceInit, .erasable])
protocol Combinable {
  func combine(_ other: Self) -> Self
}

extension CombinableWitness {
    struct Synthesized: Combinable {
        var strategy: String
        let context: Any
        var contextType: String
        init<Context>(context: Context, strategy: String? = nil) {
            self.context = context
            self.contextType = "\(String(describing: Context.self))"
            self.strategy = strategy ?? "default"
        }
        func combine(_ other: Self) -> Self {
            let table = CombinableWitness<Any>.Table()
            guard let witness = table.witness(for: contextType, label: strategy) else {
                fatalError("Table for \(Self.self) does not contain a registered witness for strategy: \(strategy)")}
            let newValue = witness.combine(context, other.context)
            return .init(context: newValue, strategy: strategy)
        }
    }
}

typealias Combining<T> = CombinableWitness<T>

extension Combining where A: Numeric {
  static var sum: Combining {
    return Combining { $0 + $1 }
  }

  static var prod: Combining {
    return Combining { $0 * $1 }
  }
}

extension Combining where A: RangeReplaceableCollection {
  static var concat: Combining {
    return Combining { $0 + $1 }
  }
}

@Witnessed([.synthesizedConformance, .utilities])
protocol Fake {
    func fake() -> Self
}

extension FakeWitness where A == Int {
    static let negative = FakeWitness(
        fake: { _ in Int.random(in: 0..<100) * -1 }
    )
}
