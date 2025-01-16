//
//  WitnessedTests.swift
//  Witness
//
//  Created by Daniel Cardona on 15/01/25.
//

import XCTest
import MacroTesting
import WitnessMacros

final class WitnessedTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      record: false,
      macros: ["Witnessed": WitnessMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testComparable() {
    assertMacro {
      """
      @Witnessed([.utilities])
      public protocol Comparable {
        func compare(_ other: Self) -> Bool
      }
      """
    } expansion: {
      """
      public protocol Comparable {
        func compare(_ other: Self) -> Bool
      }

      public struct ComparableWitness<A> {
        public let compare: (A, A) -> Bool
        public init(compare: @escaping (A, A) -> Bool) {
          self.compare = compare
        }
        public func transform<B>(pullback: @escaping (B) -> A) -> ComparableWitness<B> {
          .init(compare: {
              self.compare(pullback($0), pullback($1))
            })
        }
      }
      """
    }
  }

  func testRandomNumberGenerator() {
    assertMacro {
      """
      @Witnessed([.utilities])
      protocol RandomNumberGenerator {
        func random() -> Double
      }
      """
    } expansion: {
      """
      protocol RandomNumberGenerator {
        func random() -> Double
      }

      struct RandomNumberGeneratorWitness<A> {
        let random: (A) -> Double
        init(random: @escaping (A) -> Double) {
          self.random = random
        }
        func transform<B>(pullback: @escaping (B) -> A) -> RandomNumberGeneratorWitness<B> {
          .init(random: {
              self.random(pullback($0))
            })
        }
      }
      """
    }
  }

  func testFullyNamed() {
    assertMacro {
      """
      @Witnessed([.utilities])
      public protocol Comparable {
        func compare(_ other: Self) -> Bool
      }
      """
    } expansion: {
      """
      public protocol Comparable {
        func compare(_ other: Self) -> Bool
      }

      public struct ComparableWitness<A> {
        public let compare: (A, A) -> Bool
        public init(compare: @escaping (A, A) -> Bool) {
          self.compare = compare
        }
        public func transform<B>(pullback: @escaping (B) -> A) -> ComparableWitness<B> {
          .init(compare: {
              self.compare(pullback($0), pullback($1))
            })
        }
      }
      """
    }
  }

  func testDiffable() {
    assertMacro {
      """
      @Witnessed()
      public protocol Diffable {
        static func diff(old: Self, new: Self) -> (String, [String])?
        var data: Data { get }
        static func from(data: Data) -> Self
      }
      """
    } expansion: {
      """
      public protocol Diffable {
        static func diff(old: Self, new: Self) -> (String, [String])?
        var data: Data { get }
        static func from(data: Data) -> Self
      }

      public struct DiffableWitness<A> {
        public let diff: (A, A) -> (String, [String])?
        public let data: (A) -> Data
        public let from: (Data) -> A
        public init(diff: @escaping (A, A) -> (String, [String])?, data: @escaping (A) -> Data , from: @escaping (Data) -> A) {
          self.diff = diff
          self.data = data
          self.from = from
        }
      }
      """
    }
  }

  func testSnapshottable() {
    assertMacro {
      """
      @Witnessed()
      public protocol Snapshottable {
        associatedtype Format: Diffable
        static var pathExtension: String { get }
        var snapshot: Format { get }
      }
      """
    } expansion: {
      """
      public protocol Snapshottable {
        associatedtype Format: Diffable
        static var pathExtension: String { get }
        var snapshot: Format { get }
      }

      public struct SnapshottableWitness<A, Format> {
        public let diffable: DiffableWitness<Format>
        public let pathExtension: () -> String
        public let snapshot: (A) -> Format
        public init(diffable: DiffableWitness<Format>, pathExtension: @escaping () -> String , snapshot: @escaping (A) -> Format ) {
          self.diffable = diffable
          self.pathExtension = pathExtension
          self.snapshot = snapshot
        }
      }
      """
    }

  }

}
