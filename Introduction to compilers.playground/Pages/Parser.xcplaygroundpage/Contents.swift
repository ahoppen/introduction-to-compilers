/*:
 # Parser
 
 After lexing the source code into tokens, the *parser* parses the stream of tokens into an *abstract syntax tree (AST)*. This is a tree representation of your source code, which models the nesting that you probably see from just looking at it.
 */
let sourceFile: SwiftFile = #fileLiteral(resourceName: "Simple program.swift")
/*:
 * callout(Discover):
 Explore the AST of the different sample programs in the live view.
 

 * note:
 Since the `else` part has not been implemented yet below, “Program with else” will fail to compile.

 In the following you see the source code for parsing `if` statements in a simplified Swift compiler:
 */
class MyParser: Parser {
    override func parseIfStatement() throws -> Statement {
        // Check that the next token is indeed `if`, otherwise emit an error
        guard nextToken == .if else {
            throw CompilationError(sourceRange: nextToken.sourceRange,
                                   errorMessage: "Expected 'if' but saw \(nextToken!)")
        }
        // Save the source range in which the `if` keyword occurred
        // This will potentially be used later for error messages
        let ifRange = nextToken.sourceRange
        // Consume the token so that we can have a look at the next one
        try consumeToken()
        // Parse the if statement's condition
        let condition = try parseExpression()
        // Parse the body of the if statment
        let body = try parseBraceStatement()

        let elseBody: BraceStatement? = nil
        let elseRange: SourceRange? = nil

        // #-----------------------------------#
        // # Code to parse else statement here #
        // #-----------------------------------#

        // Construct an if statement and return it
        return IfStatement(condition: condition,
                           body: body,
                           elseBody: elseBody,
                           ifRange: ifRange,
                           elseRange: elseRange,
                           sourceRange: range(startingAt: ifRange.start))
    }
}
/*:
 Note that the code to parse the `else` part of the `if` statement is still missing.

 * callout(Experiment):
 Can you implement parsing of the `else` part similar to how the body of the `if` part gets parsed? \
Pick the example source file “Program with else” to verify that your implementation works.

 [View a possible solution](ParserSolution)

 After the source code has been transformed into an AST, the AST is *type checked*. This verifies that there is no type system violation in the code like trying to add an integer with a string `5 + "abc"` or invoking a function with the wrong type of argument. If this passes, the compiler can continue to the next phase.

 [❮ Back to the lexer](Lexer)

 [❯ Continue with IR Generation](IRGeneration)
 
 ---
 */
// Setup for the live view
import PlaygroundSupport
PlaygroundPage.current.liveView = ASTExplorer(forSourceFile: sourceFile, withParser: MyParser())
