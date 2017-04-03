public class IRGen: ASTWalker {
    private var irFunctions: [String: IRFunction] = [:]

    typealias Result = Void

    /// Generate the IR for the given AST
    ///
    /// - Parameter astRoot: The AST for which to create IR code
    /// - Returns: The generated IR
    public static func generateIR(forAST astNode: ASTNode) -> IR {
        return IRGen().generateIR(forAST: astNode)
    }

    /// Generate the IR for the given AST
    ///
    /// - Parameter astRoot: The AST for which to create IR code
    /// - Returns: The generated IR
    public func generateIR(forAST astNode: ASTNode) -> IR {
        walk(astNode)
        return IR(functions: irFunctions)
    }

    func visit(ifStatement: IfStatement) -> Void {
    }

    func visit(braceStatement: BraceStatement) -> Void {
        for statement in braceStatement.body {
            walk(statement)
        }
    }

    func visit(returnStatement: ReturnStatement) -> Void {
    }

    func visit(binaryOperatorExpression: BinaryOperatorExpression) -> Void {
    }

    func visit(integerLiteralExpression: IntegerLiteralExpression) -> Void {
    }

    func visit(stringLiteralExpression: StringLiteralExpression) -> Void {
    }

    func visit(identifierReferenceExpression: IdentifierReferenceExpression) -> Void {
    }

    func visit(functionCallExpression: FunctionCallExpression) -> Void {
    }

    func visit(functionDeclaration: FunctionDeclaration) -> Void {
        irFunctions[functionDeclaration.name] = IRFunctionGen.generateIR(forAST: functionDeclaration)
        walk(functionDeclaration.body)
    }

    func visit(variableDeclaration: VariableDeclaration) -> Void {
    }

    func visit(astRoot: ASTRoot) -> Void {
        irFunctions["main"] = IRFunctionGen.generateIR(forAST: astRoot)
        for statement in astRoot.statements {
            walk(statement)
        }
    }
}
