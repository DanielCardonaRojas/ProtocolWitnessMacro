import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WitnessMacros)
import WitnessMacros

let testMacros: [String: Macro.Type] = [
    "Witness": WitnessMacro.self,
]
#endif

final class WitnessTests: XCTestCase {
    func testMacro() throws {
        #if canImport(WitnessMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
