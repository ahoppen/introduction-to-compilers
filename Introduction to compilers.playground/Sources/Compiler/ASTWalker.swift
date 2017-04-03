protocol ASTWalker {
    associatedtype Result

    @discardableResult
    func walk(_ node: ASTNode) -> Result

    func visit(ifStatement: IfStatement) -> Result
    func visit(braceStatement: BraceStatement) -> Result
    func visit(returnStatement: ReturnStatement) -> Result
    func visit(binaryOperatorExpression: BinaryOperatorExpression) -> Result
    func visit(integerLiteralExpression: IntegerLiteralExpression) -> Result
    func visit(stringLiteralExpression: StringLiteralExpression) -> Result
    func visit(identifierReferenceExpression: IdentifierReferenceExpression) -> Result
    func visit(functionCallExpression: FunctionCallExpression) -> Result
    func visit(functionDeclaration: FunctionDeclaration) -> Result
    func visit(variableDeclaration: VariableDeclaration) -> Result
    func visit(astRoot: ASTRoot) -> Result

    func preVisit(node: ASTNode)
    func postVisit(node: ASTNode)
}

extension ASTWalker {

    func walk(_ node: ASTNode) -> Result {
        defer {
            postVisit(node: node)
        }
        preVisit(node: node)
        if let casted = node as? IfStatement {
            return visit(ifStatement: casted)
        } else if let casted = node as? BraceStatement {
            return visit(braceStatement: casted)
        } else if let casted = node as? ReturnStatement {
            return visit(returnStatement: casted)
        } else if let casted = node as? BinaryOperatorExpression {
            return visit(binaryOperatorExpression: casted)
        } else if let casted = node as? IntegerLiteralExpression {
            return visit(integerLiteralExpression: casted)
        } else if let casted = node as? StringLiteralExpression {
            return visit(stringLiteralExpression: casted)
        } else if let casted = node as? IdentifierReferenceExpression {
            return visit(identifierReferenceExpression: casted)
        } else if let casted = node as? FunctionCallExpression {
            return visit(functionCallExpression: casted)
        } else if let casted = node as? VariableDeclaration {
            return visit(variableDeclaration: casted)
        } else if let casted = node as? FunctionDeclaration {
            return visit(functionDeclaration: casted)
        } else if let casted = node as? ASTRoot {
            return visit(astRoot: casted)
        } else {
            fatalError("Unknown AST node \(type(of: node))")
        }
    }

    func preVisit(node: ASTNode) {
    }

    func postVisit(node: ASTNode) {
    }
}

protocol ThrowingASTWalker {
    associatedtype Result

    func visit(ifStatement: IfStatement) throws -> Result
    func visit(braceStatement: BraceStatement) throws -> Result
    func visit(returnStatement: ReturnStatement) throws -> Result
    func visit(binaryOperatorExpression: BinaryOperatorExpression) throws -> Result
    func visit(integerLiteralExpression: IntegerLiteralExpression) throws -> Result
    func visit(stringLiteralExpression: StringLiteralExpression) throws -> Result
    func visit(identifierReferenceExpression: IdentifierReferenceExpression) throws -> Result
    func visit(functionCallExpression: FunctionCallExpression) throws -> Result
    func visit(functionDeclaration: FunctionDeclaration) throws -> Result
    func visit(variableDeclaration: VariableDeclaration) throws -> Result
    func visit(astRoot: ASTRoot) throws -> Result

    func preVisit(node: ASTNode)
    func postVisit(node: ASTNode)
}

extension ThrowingASTWalker {

    @discardableResult
    func walk(_ node: ASTNode) throws -> Result {
        defer {
            postVisit(node: node)
        }
        preVisit(node: node)
        if let casted = node as? IfStatement {
            return try visit(ifStatement: casted)
        } else if let casted = node as? BraceStatement {
            return try visit(braceStatement: casted)
        } else if let casted = node as? ReturnStatement {
            return try visit(returnStatement: casted)
        } else if let casted = node as? BinaryOperatorExpression {
            return try visit(binaryOperatorExpression: casted)
        } else if let casted = node as? IntegerLiteralExpression {
            return try visit(integerLiteralExpression: casted)
        } else if let casted = node as? StringLiteralExpression {
            return try visit(stringLiteralExpression: casted)
        } else if let casted = node as? IdentifierReferenceExpression {
            return try visit(identifierReferenceExpression: casted)
        } else if let casted = node as? FunctionCallExpression {
            return try visit(functionCallExpression: casted)
        } else if let casted = node as? VariableDeclaration {
            return try visit(variableDeclaration: casted)
        } else if let casted = node as? FunctionDeclaration {
            return try visit(functionDeclaration: casted)
        } else if let casted = node as? ASTRoot {
            return try visit(astRoot: casted)
        } else {
            fatalError("Unknown AST node \(type(of: node))")
        }
    }

    func preVisit(node: ASTNode) {
    }

    func postVisit(node: ASTNode) {
    }
}
