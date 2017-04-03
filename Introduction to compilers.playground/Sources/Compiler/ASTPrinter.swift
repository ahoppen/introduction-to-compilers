/// Class that prints an AST into a string that can later be retrieved as the output property
class ASTPrinter: ASTWalker {
    typealias Result = Void

    /// The output of the printer after `print` has been called
    public var output: String = ""

    /// Keep a stack of variables that indicate whether a body has been printed for a node
    /// and if the closing paranthesis shall thus be indented or not
    private var bodyPrinted: [Bool] = []
    private var indentation = 0

    public func print(_ node: ASTNode) {
        walk(node)
    }

    private func setBodyPrinted() {
        bodyPrinted[bodyPrinted.count - 1] = true
    }

    private func print(_ string: String, withIndentation: Bool = true, withNewline: Bool = true) {
        if withIndentation {
            for _ in 0..<indentation {
                output += "  "
            }
        }
        output += string
        if withNewline {
            output += "\n"
        }
    }

    // MARK: - ASTWalker

    func visit(ifStatement: IfStatement) -> Void {
        setBodyPrinted()
        print("", withIndentation: false)
        walk(ifStatement.condition)
        walk(ifStatement.body)
        if let elseBody = ifStatement.elseBody {
            walk(elseBody)
        }
    }

    func visit(braceStatement: BraceStatement) -> Void {
        if braceStatement.body.count > 0 {
            print("", withIndentation: false)
            setBodyPrinted()
        }
        for statement in braceStatement.body {
            walk(statement)
        }
    }

    func visit(returnStatement: ReturnStatement) -> Void {
        setBodyPrinted()
        print("", withIndentation: false)
        walk(returnStatement.expression)
    }

    func visit(binaryOperatorExpression: BinaryOperatorExpression) -> Void {
        setBodyPrinted()
        print(" operator=\(binaryOperatorExpression.operator)", withIndentation: false)
        walk(binaryOperatorExpression.lhs)
        walk(binaryOperatorExpression.rhs)
    }

    func visit(integerLiteralExpression: IntegerLiteralExpression) -> Void {
        print(" value=\(integerLiteralExpression.value)", withIndentation: false, withNewline: false)
    }

    func visit(stringLiteralExpression: StringLiteralExpression) -> Void {
        print(" value=\(stringLiteralExpression.value)", withIndentation: false, withNewline: false)
    }

    func visit(identifierReferenceExpression: IdentifierReferenceExpression) -> Void {
        print(" name=\(identifierReferenceExpression.name)", withIndentation: false, withNewline: false)
    }

    func visit(functionCallExpression: FunctionCallExpression) -> Void {
        print(" name=\(functionCallExpression.functionName)", withIndentation: false, withNewline: false)
        if !functionCallExpression.arguments.isEmpty {
            setBodyPrinted()
            print("", withIndentation: false)
        }
        for argument in functionCallExpression.arguments {
            walk(argument)
        }
    }

    func visit(variableDeclaration: VariableDeclaration) -> Void {
        print(" name=\(variableDeclaration.name) type=\(variableDeclaration.type)", withIndentation: false, withNewline: false)
    }

    func visit(functionDeclaration: FunctionDeclaration) -> Void {
        print(" name=\(functionDeclaration.name) returnType=\(functionDeclaration.returnType)", withIndentation: false)
        setBodyPrinted()
        for parameter in functionDeclaration.parameters {
            walk(parameter)
        }
        walk(functionDeclaration.body)
    }


    func visit(astRoot: ASTRoot) -> Void {
        if astRoot.statements.count > 0 {
            print("", withIndentation: false)
            setBodyPrinted()
        }

        for statement in astRoot.statements {
            walk(statement)
        }
    }

    func preVisit(node: ASTNode) {
        print("(\(type(of: node))", withNewline: false)
        indentation += 1
        bodyPrinted.append(false)
    }

    func postVisit(node: ASTNode) {
        indentation -= 1
        if bodyPrinted[bodyPrinted.count - 1] {
            print(")")
        } else {
            print(")", withIndentation: false)
        }
        bodyPrinted.removeLast()
    }
}
