//
//  SwiftSyntax+Extensions.swift
//  Witness
//
//  Created by Daniel Cardona on 3/01/25.
//
import SwiftSyntax

extension FunctionDeclSyntax {
  func isModifiedWith(_ keyword: Keyword) -> Bool {
    modifiers.contains(where: { $0.name.text == TokenSyntax.keyword(keyword).text})
  }
}

extension SubscriptDeclSyntax {
  func isModifiedWith(_ keyword: Keyword) -> Bool {
    modifiers.contains(where: { $0.name.text == TokenSyntax.keyword(keyword).text})
  }
}

extension VariableDeclSyntax {
  func isModifiedWith(_ keyword: Keyword) -> Bool {
    modifiers.contains(where: { $0.name.text == TokenSyntax.keyword(keyword).text})
  }
}

extension FunctionEffectSpecifiersSyntax {
  func typeEffectSpecifiers() -> TypeEffectSpecifiersSyntax {
    return TypeEffectSpecifiersSyntax(
      asyncSpecifier: asyncSpecifier,
      throwsClause: throwsClause
    )
  }
}

extension GenericParameterSyntax {
  func toGenericArgumentSyntax() -> GenericArgumentSyntax {
    .init(
      argument: IdentifierTypeSyntax(name: name)
    )

  }
}

