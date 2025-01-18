import Witness
import Foundation

@Witnessed([.utilities])
public protocol Comparable {
  func compare(_ other: Self) -> Bool
}

@Witnessed()
protocol FullyNamed {
  var fullName: String { get }
}

@Witnessed([.utilities])
protocol RandomNumberGenerator {
  func random() -> Double
}

@Witnessed([.utilities, .conformanceInit])
protocol Combinable {
  func combine(_ other: Self) -> Self
}

typealias Combining<A> = CombinableWitness<A>

@Witnessed([.utilities, .conformanceInit])
public protocol Diffable {
  static func diff(old: Self, new: Self) -> (String, [String])?
  var data: Data { get }
  static func from(data: Data) -> Self
}

typealias Diffing<A> = DiffableWitness<A>

@Witnessed([.utilities, .conformanceInit])
protocol Snapshottable {
  associatedtype Format: Diffable
  static var pathExtension: String { get }
  var snapshot: Format { get }
}

typealias Snapshotting<Value, Format: Diffable> = SnapshottableWitness<Value, Format>

@Witnessed
protocol Convertible {
  associatedtype To
  func convert() -> To
}

typealias Converting<A, To> = ConvertibleWitness<A, To>

