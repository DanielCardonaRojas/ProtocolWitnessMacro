//
//  WitnessGenerator+Transformed.swift
//  Witness
//
//  Created by Daniel Cardona on 8/01/25.
//
import SwiftSyntax
import SwiftSyntaxBuilder

/// Generates utility method for transforming  a `Witness<A>` into a `Witness<B>`
extension WitnessGenerator {
  static func witnessTransformation(
    _ protocolDecl: ProtocolDeclSyntax
  ) -> MemberBlockItemSyntax? {

    let variances = witnessStructVariance(protocolDecl)
    // The name of the witness struct we generated, e.g., `CombinableWitness`.
    let witnessName = witnessStructName(protocolDecl) // e.g. "CombinableWitness"

    var member: MemberBlockItemSyntax?

    // If we detect `.invariant` or a mix of covariant+contravariant, we typically want `iso`.
    if variances.contains(.invariant) ||
       (variances.contains(.contravariant) && variances.contains(.covariant)) {
      member = MemberBlockItemSyntax(decl: transformedWitness(semantic: .iso, protocolDecl: protocolDecl, witnessName: witnessName))
    } else {
      // If strictly contravariant => generate pullback
      if variances.contains(.contravariant) {
        member = MemberBlockItemSyntax(decl: transformedWitness(semantic: .pullback, protocolDecl: protocolDecl, witnessName: witnessName))
      } else if variances.contains(.covariant) { // If strictly covariant => generate map
        member = MemberBlockItemSyntax(decl: transformedWitness(semantic: .map, protocolDecl: protocolDecl, witnessName: witnessName))
      }
    }
    return member
  }

  /// Generates method transforming witness to another type
  /// ```swift
  /// extension <WitnessName> {
  ///   func pullback<B>(_ f: @escaping (B) -> A) -> <WitnessName><B> {
  ///     .init(combine: { b1, b2 in
  ///       self.combine(f(b1), f(b2))
  ///     })
  ///   }
  /// }
  /// ```
  /// or:
  /// ```swift
  /// extension <WitnessName> {
  ///   func map<B>(_ f: @escaping (A) -> B) -> <WitnessName><B> {
  ///     .init(combine: { a1, a2 in
  ///       let result = self.combine(a1, a2)
  ///       return f(result)
  ///     })
  ///   }
  /// }
  /// ```
  /// or:
  /// ```swift
  /// extension <WitnessName> {
  ///   func iso<B>(
  ///     _ pullback: @escaping (B) -> A,
  ///     map: @escaping (A) -> B
  ///   ) -> <WitnessName><B> {
  ///     .init(combine: { b1, b2 in
  ///       let r = self.combine(pullback(b1), pullback(b2))
  ///       return map(r)
  ///     })
  ///   }
  /// }
  /// ```
  static func transformedWitness(
    semantic: TransformedWitnessSemantic,
    protocolDecl: ProtocolDeclSyntax,
    witnessName: TokenSyntax
  ) -> FunctionDeclSyntax {
    // `func iso<B>(_ pullback: @escaping (B) -> A, map: @escaping (A) -> B) -> <WitnessName><B>`
    FunctionDeclSyntax(
      modifiers: .init(itemsBuilder: {
        if let accessModifier = accessModifier(protocolDecl) {
          accessModifier
        }
      }),
      name: .identifier(semantic.rawValue),
      genericParameterClause: GenericParameterClauseSyntax(
        parameters: GenericParameterListSyntax {
          GenericParameterSyntax(name: .identifier("B"))
        }
      ),
      signature: FunctionSignatureSyntax(
        parameterClause: FunctionParameterClauseSyntax {
          // ( _ pullback: @escaping (B) -> A )
          if semantic == .iso || semantic == .pullback {
            FunctionParameterSyntax(
              firstName: .identifier("pullback"),
              colon: .colonToken(),
              type: AttributedTypeSyntax(
                specifiers: .init(itemsBuilder: {

                }),
                attributes: .init(
                  itemsBuilder: {
                    AttributeSyntax(
                      atSign: .atSignToken(),
                      attributeName: IdentifierTypeSyntax(name: .identifier("escaping"))
                    )
                  }),
                baseType:
                  FunctionTypeSyntax(
                    parameters: TupleTypeElementListSyntax {
                      TupleTypeElementSyntax(
                        type: IdentifierTypeSyntax(name: .identifier("B"))
                      )
                    },
                    returnClause: ReturnClauseSyntax(
                      type: IdentifierTypeSyntax(name: .identifier(genericLabel))
                    )
                  )
              )
            )
          }
          // ( map: @escaping (A) -> B )
          if semantic == .iso || semantic == .map {
            FunctionParameterSyntax(
              firstName: .identifier("map"),
              colon: .colonToken(),
              type: AttributedTypeSyntax(
                specifiers: .init(itemsBuilder: {

                }),
                attributes: .init(
                  itemsBuilder: {
                    AttributeSyntax(
                      atSign: .atSignToken(),
                      attributeName: IdentifierTypeSyntax(name: .identifier("escaping"))
                    )
                  }),
                baseType: FunctionTypeSyntax(
                  parameters: TupleTypeElementListSyntax {
                    TupleTypeElementSyntax(
                      type: IdentifierTypeSyntax(name: .identifier(genericLabel))
                    )
                  },
                  returnClause: ReturnClauseSyntax(
                    type: IdentifierTypeSyntax(name: .identifier("B"))
                  )
                )
              )
            )
          }
        },
        returnClause: ReturnClauseSyntax(
          type: TypeSyntax(
            genericType(witnessName: witnessName, typeArg: "B")
          )
        )
      )
    ) {
      CodeBlockItemListSyntax {
        transformedInstance(protocolDecl)
      }
    }
  }

  static func transformedInstance(_ protocolDecl: ProtocolDeclSyntax) -> FunctionCallExprSyntax {
    FunctionCallExprSyntax(
      calledExpression: MemberAccessExprSyntax(
        declName: DeclReferenceExprSyntax(
          baseName: .identifier("init")
        )
      ),
      leftParen: .leftParenToken(),
      arguments: .init(itemsBuilder: {
        for argument in constructorArguments(protocolDecl) {
          argument
        }
      }),
      rightParen: .rightParenToken()
    )

  }

  static func constructorArguments(_ protocolDecl: ProtocolDeclSyntax) -> [LabeledExprSyntax] {
    protocolDecl.memberBlock.members
      .compactMap(
{
        if let functionDecl = $0.decl.as(FunctionDeclSyntax.self) {
          return LabeledExprSyntax(
            label: functionDecl.name,
            colon: .colonToken(),
            expression: transformedClosure(functionDecl, protocolDecl: protocolDecl)
          )
        }

        if let variableDecl = $0.decl.as(VariableDeclSyntax.self),
           let identifier = variableDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self) {
          return LabeledExprSyntax(
            label: identifier.identifier,
            colon: .colonToken(),
            expression: transformedVariableClosure(variableDecl, protocolDecl: protocolDecl)
          )
        }

        return nil
      })
  }


  static func transformedVariableClosure(_ variableDecl: VariableDeclSyntax, protocolDecl: ProtocolDeclSyntax) -> ClosureExprSyntax {
    let generics = associatedTypeToGenericParam(protocolDecl, primary: nil)
    let closureType = variableRequirementWitnessType(variableDecl)
    let variableName = variableDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier ?? .init(stringLiteral: "Unknown")
    let variableType = variableDecl.bindings.first?.typeAnnotation
    let closureCall = FunctionCallExprSyntax(
      calledExpression: MemberAccessExprSyntax(
        base: DeclReferenceExprSyntax(baseName: .identifier("self")),
        declName: DeclReferenceExprSyntax(baseName: variableName)
      ),
      leftParen: .leftParenToken(),
      rightParen: .rightParenToken(),
      argumentsBuilder: {
        // Rest of params
        for (index, parameter) in closureType.parameters.enumerated() {
          if varianceOf(parameter: parameter, generics: generics) == .contravariant {
            LabeledExprSyntax(
              expression: FunctionCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(
                  baseName: .identifier("pullback")
                ),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(
                  arrayLiteral: .init(
                    expression: DeclReferenceExprSyntax(
                      baseName: .dollarIdentifier("$\(index)")
                    )
                  )
                ),
                rightParen: .rightParenToken()
              )
            )
          } else {
            LabeledExprListSyntax(
              arrayLiteral: .init(
                expression: DeclReferenceExprSyntax(
                  baseName: .dollarIdentifier("$\(index)")
                )
              )
            )
          }
        }
      }
    )

    // TODO: Also check for associated types
    let hasSelfInType = variableType?.contains(targetTypeName: "Self") ?? false

    let variance: Variance = hasSelfInType ? .covariant : .invariant

    // If contains Self in the return type then map the return value
    if variance == .covariant {
      return ClosureExprSyntax(
        signature: nil,
        statementsBuilder: {
          CodeBlockItemSyntax(
            item: .expr(
              ExprSyntax(
                FunctionCallExprSyntax(
                  calledExpression: DeclReferenceExprSyntax(
                    baseName: .identifier("map")
                  ),
                  leftParen: .leftParenToken(),
                  arguments: .init(
                    itemsBuilder: {
                      LabeledExprSyntax(expression: closureCall)
                      }
                  ),
                  rightParen: .rightParenToken()
                )
              )
            )
          )
        }
      )
    }

    // Does not have contain Self in the return type
    return ClosureExprSyntax(
      signature: nil,
      statementsBuilder: {
        CodeBlockItemSyntax(
          item: .expr(
            ExprSyntax(
              closureCall
            )
          )
        )
      }
    )
  }

  /// Creates an a closure expression with converted input and outputs.
  ///
  /// This is used in the transform the closures of a Witness<A> to a Witness<B>
  static private func transformedClosure(_ functionDecl: FunctionDeclSyntax, protocolDecl: ProtocolDeclSyntax) -> ClosureExprSyntax {
    let generics = associatedTypeToGenericParam(protocolDecl, primary: nil)
    let closureType = functionRequirementWitnessType(functionDecl)
    let closureCall = FunctionCallExprSyntax(
      calledExpression: MemberAccessExprSyntax(
        base: DeclReferenceExprSyntax(baseName: .identifier("self")),
        declName: DeclReferenceExprSyntax(baseName: functionDecl.name)
      ),
      leftParen: .leftParenToken(),
      rightParen: .rightParenToken(),
      argumentsBuilder: {
        // Rest of params
        for (index, parameter) in closureType.parameters.enumerated() {
          if varianceOf(parameter: parameter, generics: generics) == .contravariant {
            LabeledExprSyntax(
              expression: FunctionCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(
                  baseName: .identifier("pullback")
                ),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(
                  arrayLiteral: .init(
                    expression: DeclReferenceExprSyntax(
                      baseName: .dollarIdentifier("$\(index)")
                    )
                  )
                ),
                rightParen: .rightParenToken()
              )
            )
          } else {
            LabeledExprListSyntax(
              arrayLiteral: .init(
                expression: DeclReferenceExprSyntax(
                  baseName: .dollarIdentifier("$\(index)")
                )
              )
            )
          }
        }
      }
    )

    let variance = variance(
      functionSignature: functionDecl.signature,
      generics: generics
    )

    // If contains Self in the return type then map the return value
    if variance == .covariant || variance == .invariant {
      return ClosureExprSyntax(
        signature: nil,
        statementsBuilder: {
          CodeBlockItemSyntax(
            item: .expr(
              ExprSyntax(
                FunctionCallExprSyntax(
                  calledExpression: DeclReferenceExprSyntax(
                    baseName: .identifier("map")
                  ),
                  leftParen: .leftParenToken(),
                  arguments: .init(
                    itemsBuilder: {
                      LabeledExprSyntax(expression: closureCall)
                      }
                  ),
                  rightParen: .rightParenToken()
                )
              )
            )
          )
        }
      )
    }

    // Does not have contain Self in the return type
    return ClosureExprSyntax(
      signature: nil,
      statementsBuilder: {
        CodeBlockItemSyntax(
          item: .expr(
            ExprSyntax(
              closureCall
            )
          )
        )
      }
    )
  }

  /// **Core method**: Determines the variance of a function signature by checking
  /// how the generic parameters are used in the function's parameter list (input)
  /// and return type (output).
  ///
  /// - Parameters:
  ///   - functionSignature: The syntax node describing the function signature.
  ///   - generics: The generic parameters (e.g., `T`, `U`) declared on the function.
  /// - Returns: A `Variance` value (`.contravariant`, `.covariant`, or `.invariant`).
  static func variance(
      functionSignature: FunctionSignatureSyntax,
      generics: [GenericParameterSyntax]
  ) -> Variance {
      // 1) Collect the declared generic names: e.g., ["T", "U", ...]
      var declaredGenericNames = Set(generics.map { $0.name.text })
      declaredGenericNames.insert("Self")

      // 2) Collect generics used in parameter types (input position).
      //    We'll iterate through every parameter and walk its type syntax.
      var genericsInParams = Set<String>()
      for param in functionSignature.parameterClause.parameters {
          let paramType = param.type
          let collector = GenericNameCollector(declaredGenerics: declaredGenericNames)
          collector.walk(paramType)
          genericsInParams.formUnion(collector.foundGenerics)
      }

      // 3) Collect generics used in the return type (output position).
      var genericsInReturn = Set<String>()
      if let returnClause = functionSignature.returnClause {
          let returnType = returnClause.type
          let collector = GenericNameCollector(declaredGenerics: declaredGenericNames)
          collector.walk(returnType)
          genericsInReturn.formUnion(collector.foundGenerics)
      }

      // 4) Apply simple variance logic:
      //    - If any generic is in both input and output, => invariant
      //    - If generics are only in parameters => contravariant
      //    - If generics are only in return => covariant
      //    - Otherwise (e.g., none used at all) => invariant
      let intersection = genericsInParams.intersection(genericsInReturn)
      if !intersection.isEmpty {
          return .invariant
      } else if !genericsInParams.isEmpty && genericsInReturn.isEmpty {
          return .contravariant
      } else if genericsInParams.isEmpty && !genericsInReturn.isEmpty {
          return .covariant
      } else {
          // If no generics are found at all or any other fallback scenario:
          return .invariant
      }
  }

  static func varianceOf(
    parameter: TupleTypeElementSyntax,
    generics: [GenericParameterSyntax]
  ) -> Variance {
    var declaredGenericNames = Set(generics.map { $0.name.text })
    declaredGenericNames.insert(Self.genericLabel)
    let collector = GenericNameCollector(declaredGenerics: declaredGenericNames)
    collector.walk(parameter)
    let genericsInParamType = collector.foundGenerics

    if !genericsInParamType.intersection(declaredGenericNames).isEmpty {
      return .contravariant
    }

    return .invariant
  }

  /// Determines if the generated witness struct need a pullback, map or iso method.
  /// if the set contains a covariant and contravariant then an iso is required
  /// if the set contains covariant and not contravariant then a map is required
  /// if the set contains a contravariant and not a covariant then a pullback is required
  static func witnessStructVariance(_ protocolDecl: ProtocolDeclSyntax) -> Set<Variance> {
    let generics = associatedTypeToGenericParam(protocolDecl, primary: nil)
    let variances: [Variance] = protocolDecl.memberBlock.members.compactMap { member in
      guard let functionDecl = member.decl.as(FunctionDeclSyntax.self) else {
        return nil
      }
      return variance(functionSignature: functionDecl.signature, generics: generics)
    }

    return Set(variances)
  }
}
