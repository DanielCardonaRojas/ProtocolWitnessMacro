//
//  WitnessLookup.swift
//  Witness
//
//  Created by Daniel Cardona on 30/06/25.
//

/// Helper for reducing code generation on specific witness tables
public struct WitnessLookUpTable<WitnessType> {
    var witnessType: Any.Type
    /// Erased type for the witness. For example `Witness<Any>`
    public let table: WitnessTable

    public init() {
        self.witnessType = WitnessType.self
        self.table = WitnessRegistry.shared.table(for: WitnessType.self)
    }

    public func witness(for type: String, label: String? = nil) -> WitnessType? {
        table.read(type: type, label: label) as? WitnessType
    }

    public func witness<A>(for type: A.Type, label: String? = nil) -> WitnessType? {
        table.read(type: "\(type)", label: label) as? WitnessType
    }

}

