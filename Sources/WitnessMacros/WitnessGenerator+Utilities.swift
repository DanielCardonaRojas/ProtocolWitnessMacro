//
//  WitnessGenerator+Utilities.swift
//  Witness
//
//  Created by Daniel Cardona on 8/01/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import Shared

/// Simple extensions are reused multiple times
extension WitnessGenerator {

  /// Generates the name for the generated witness.
  /// MyProtocol -> MyProtocolWitness
  static func witnessStructName(_ protocolDecl: ProtocolDeclSyntax) -> TokenSyntax {
    "\(raw: protocolDecl.name.text)Witness"
  }

  /// Retrieves the access modifier of the protocol declaration
  static func accessModifier(_ protocolDecl: ProtocolDeclSyntax) -> DeclModifierSyntax? {
    protocolDecl.modifiers.first(where: { modifier in
      [TokenSyntax.keyword(.public), .keyword(.private), .keyword(.internal)].contains( where: { $0.text == modifier.name.text })
    })
  }

  /// Helper to produce "<witnessName><B>"
  static func genericType(witnessName: TokenSyntax, typeArg: String) -> some TypeSyntaxProtocol {
    return IdentifierTypeSyntax(
      name: witnessName,
      genericArgumentClause: GenericArgumentClauseSyntax(
        arguments: GenericArgumentListSyntax {
          GenericArgumentSyntax(argument: IdentifierTypeSyntax(name: .identifier(typeArg)))
        }
      )
    )
  }
  
  /// Produces `A` in a closures parameter type in for example: `(inout A) -> Bool`
  static func inoutSelfTupleTypeElement() -> TupleTypeElementSyntax {
    TupleTypeElementSyntax(
      type: AttributedTypeSyntax(
        specifiers: .init(itemsBuilder: {
          .init(specifier: .keyword(.inout))
        }),
        baseType: IdentifierTypeSyntax(
          name: TokenSyntax(stringLiteral: Self.genericLabel)
        )
      )
    )
  }

  /// Produces `A` in a closures parameter type in for example: `(A) -> Bool`
  static func selfTupleTypeElement() -> TupleTypeElementSyntax {
    TupleTypeElementSyntax(
      type: IdentifierTypeSyntax(
        name: TokenSyntax(stringLiteral: Self.genericLabel)
      )
    )
  }

  static func replaceSelf(typeSyntax: TypeSyntaxProtocol) -> TypeSyntaxProtocol {
    if let syntax = typeSyntax.as(IdentifierTypeSyntax.self), syntax.name.text == TokenSyntax.keyword(.Self).text {
      return IdentifierTypeSyntax(
        name: TokenSyntax(stringLiteral: Self.genericLabel)
      )
    }

    return typeSyntax
  }

  static func comment(_ string: String) -> MissingDeclSyntax {
    MissingDeclSyntax(placeholder: "// ")
      .with(\.trailingTrivia, .lineComment(string))
  }

  static func associatedTypes(_ protocolDecl: ProtocolDeclSyntax) -> [AssociatedTypeDeclSyntax] {
    protocolDecl.memberBlock.members.compactMap({ $0.decl.as(AssociatedTypeDeclSyntax.self) })
  }

  /// Creates a type with the form <MyProtocolName>Witness<GENERIC_TYPE_NAME> e.g: DiffableWitness<Format>
  static func witnessTypeNamed(_ name: String, genericTypeName: String? = nil) -> IdentifierTypeSyntax {
    IdentifierTypeSyntax(
      name: "\(raw: name)Witness",
      genericArgumentClause: GenericArgumentClauseSyntax(
        arguments: GenericArgumentListSyntax(
          arrayLiteral: GenericArgumentSyntax(
            argument: IdentifierTypeSyntax(
              name: TokenSyntax(stringLiteral: genericTypeName ?? Self.genericLabel)
            )
          )
        )
      )
    )
  }

  /// Determines if the macro arguments contains a specific code generation option.
  static func containsOption(_ option: WitnessOptions, protocolDecl: ProtocolDeclSyntax) -> Bool {
    let attribute = protocolDecl.attributes.first(where: { attribute in
      guard let attr = attribute.as(AttributeSyntax.self) else {
        return false
      }

      guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
        // No arguments or unexpected format
        return false
      }

      let hasConformance = arguments.contains(where: { element in
        element.expression.description.contains(option.rawValue)
      })

      return hasConformance
    })

    return attribute != nil
  }

}