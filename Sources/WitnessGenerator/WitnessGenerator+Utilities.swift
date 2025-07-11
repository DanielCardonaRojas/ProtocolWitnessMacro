//
//  WitnessGenerator+Utilities.swift
//  Witness
//
//  Created by Daniel Cardona on 8/01/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import WitnessTypes

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
    genericType(
      witnessName: witnessName,
      genericArgumentClause: GenericArgumentClauseSyntax(
        arguments: GenericArgumentListSyntax {
          GenericArgumentSyntax(argument: IdentifierTypeSyntax(name: .identifier(typeArg)))
        }
      )
    )
  }

  static func genericType(witnessName: TokenSyntax, genericArgumentClause: GenericArgumentClauseSyntax) -> some TypeSyntaxProtocol {
    return IdentifierTypeSyntax(
      name: witnessName,
      genericArgumentClause: genericArgumentClause
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

  static func replaceSelf(typeSyntax: TypeSyntaxProtocol) -> TypeSyntax {
    if let syntax = typeSyntax.as(IdentifierTypeSyntax.self), syntax.name.text == TokenSyntax.keyword(.Self).text {
      return TypeSyntax(IdentifierTypeSyntax(
        name: TokenSyntax(stringLiteral: Self.genericLabel)
      ))
    }

    return TypeSyntax(typeSyntax)
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

    static func codeGenOptions(protocolDecl: ProtocolDeclSyntax) -> WitnessOptions? {
        for attribute in protocolDecl.attributes {
            guard let attr = attribute.as(AttributeSyntax.self) else {
                return nil
            }

            guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
                // No arguments or unexpected format
                return nil
            }
            for argument in arguments {
                guard let parsedOption = WitnessOptions(stringLiteral: argument.expression.description) else {
                    continue
                }
                return parsedOption
            }
        }
        return nil
    }

  /// Groups a collection of declarations and separates them with a new line as well as adding an optional header comment
  static func groupedDeclarations(
    _ items: [MemberBlockItemSyntax],
    comment: String? = nil,
    separated: Bool = false
  ) -> [MemberBlockItemSyntax] {
    let count = items.count
    var updatedItems = [MemberBlockItemSyntax]()

    for (index, member) in items.enumerated() {
      let item = member
        .withTrivia(
          lineBreak: separated || index == count - 1,
          comment: index == 0 ? comment : nil
        )

      updatedItems.append(item)
    }

    return updatedItems
  }

}

extension MemberBlockItemSyntax {
  func withTrivia(lineBreak: Bool = false, comment: String? = nil) -> MemberBlockItemSyntax {
    var item = self
    if lineBreak {
      item = item.with(\.trailingTrivia, .newline)
    }

    if let comment {
      item = item.with(\.leadingTrivia, .lineComment(comment) + .newline)
    }

    return item
  }
}
