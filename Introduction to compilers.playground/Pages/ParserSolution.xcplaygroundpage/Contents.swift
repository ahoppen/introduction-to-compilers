/*:
 # Parser Experiment Solution
 
 A possible solution to successfully implement the parsing of the else part is to change the variables `elseBody` and `elseRange` from `let` to `var` and perform the following instead of the placeholder:
 
 - Check if the next token is `else` (`nextToken == .else`)
 - If yes, retrieve the `else` token's range (`elseRange = nextToken.sourceRange`)
 - Consume the `else` token (`try consumeToken()`)
 - Parse the else body and store it (`elseBody = try parseBraceStatement()`)
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
        // Consume the so that we can have a look at the next token
        try consumeToken()
        // Parse the if statement's condition
        let condition = try parseExpression()
        // Parse the body of the if statment
        let body = try parseBraceStatement()

        // ================================== //

        var elseBody: BraceStatement? = nil
        var elseRange: SourceRange? = nil

        // Check if the next token is `else`
        if nextToken == .else {
            // Retrieve the else token's source range
            elseRange = nextToken.sourceRange
            // Consume the `else` token since we have handled it
            try consumeToken()
            // Parse the else body
            elseBody = try parseBraceStatement()
        }

        // ================================== //

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
 [❮ Back to the parser](Parser)

 */
