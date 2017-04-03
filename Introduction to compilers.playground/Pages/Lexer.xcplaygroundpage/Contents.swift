/*:
 # Lexer

 For a computer, even source code is just a stream of characters.

 To understand the code's semantics, it first *lexes* the stream of characters into tokens. A token is, for example, the keyword `if`, or the string literal `"hello world"`. These tokens are classified into categories like the different brackets, identifiers, and operators.

 * callout(Discover):
 Hover over the source code in the live view to see the different tokens it consists of. \
Select different example source files to see how they get lexed.

 
 * note:
 Make sure the live view is activated to see the source code.

 */
let sourceFile: SwiftFile = #fileLiteral(resourceName: "Simple program.swift")
/*:
 [❮ Back to the introduction](Introduction)

 [❯ Continue with the parser](Parser)
 
 ---
 */
// Setup for the live view
import PlaygroundSupport
PlaygroundPage.current.liveView = TokensExplorer(forSourceFile: sourceFile)
