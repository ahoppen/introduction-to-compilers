/// Represents the different types an expression can return
public enum Type {
    case integer
    case boolean
    case string
    case function
    case none

    public static func fromString(_ string: String) -> Type? {
        switch string {
        case "Int":
            return .integer
        case "Bool":
            return .boolean
        case "String":
            return .string
        case "Void":
            return .none
        default:
            return nil
        }
    }
}


fileprivate class LookupScope {
    let previousScope: LookupScope?
    var lookupTable: [String: Declaration] = [:]

    init(previousScope: LookupScope?) {
        self.previousScope = previousScope
    }

    func add(_ variable: VariableDeclaration) {
        lookupTable[variable.name] = variable
    }

    func add(_ variable: FunctionDeclaration) {
        lookupTable[variable.name] = variable
    }

    func lookup(_ name: String) -> Declaration? {
        if let decl = lookupTable[name] {
            return decl
        }
        return previousScope?.lookup(name)
    }
}

/// Checks that there are no type-system violations in a given AST
public class Typechecker: ThrowingASTWalker {
    typealias Result = Type

    private var lookupScope = LookupScope(previousScope: nil)
    private var functions: [String: FunctionDeclaration] = [:]

    public init() {
    }

    /// Check that there are no type-system violation in the given AST. Returns if there are no
    /// violations and throws an error if a violation was found
    ///
    /// - Parameter node: The AST to check
    /// - Throws: A `CompilationError` if a type system violation was found
    public static func typecheck(node: ASTNode) throws {
        let typechecker = Typechecker()
        try typechecker.typecheck(node: node)
    }

    public func typecheck(node: ASTNode) throws {
        _ = try self.walk(node)
    }

    // MARK: - ASTWalker

    func visit(ifStatement: IfStatement) throws -> Type {
        _ = try walk(ifStatement.condition)
        _ = try walk(ifStatement.body)
        if let elseBody = ifStatement.elseBody {
            _ = try walk(elseBody)
        }
        return .none
    }

    func visit(braceStatement: BraceStatement) throws -> Type {
        for statement in braceStatement.body {
            _ = try walk(statement)
        }
        return .none
    }

    func visit(returnStatement: ReturnStatement) throws -> Type {
        try walk(returnStatement.expression)
        return .none
    }

    func visit(binaryOperatorExpression: BinaryOperatorExpression) throws -> Type {
        let lhsType = try walk(binaryOperatorExpression.lhs)
        let rhsType = try walk(binaryOperatorExpression.rhs)
        switch (binaryOperatorExpression.operator) {
        case .add, .sub:
            if lhsType == .integer && rhsType == .integer {
                return .integer
            } else {
                throw CompilationError(sourceRange: binaryOperatorExpression.sourceRange,
                                       errorMessage: "The left-hand-side and right-hand side of '\(binaryOperatorExpression.operator.sourceCodeName)' need to be integers")
            }
        case .equal, .lessOrEqual:
            if lhsType == .integer && rhsType == .integer {
                return .boolean
            } else {
                throw CompilationError(sourceRange: binaryOperatorExpression.sourceRange,
                                       errorMessage: "The left-hand-side and right-hand side of '==' need to be integers")
            }
        }
    }

    func visit(integerLiteralExpression: IntegerLiteralExpression) throws -> Type {
        return .integer
    }

    func visit(stringLiteralExpression: StringLiteralExpression) throws -> Type {
        return .string
    }

    func visit(identifierReferenceExpression: IdentifierReferenceExpression) throws -> Type {
        guard let referencedDeclaration = lookupScope.lookup(identifierReferenceExpression.name) else {
            throw CompilationError(sourceRange: identifierReferenceExpression.sourceRange,
                                   errorMessage: "Referenced undefined variable \(identifierReferenceExpression.name)")
        }
        identifierReferenceExpression.referencedDeclaration = referencedDeclaration

        return referencedDeclaration.type
    }

    func visit(functionCallExpression: FunctionCallExpression) throws -> Type {
        for argument in functionCallExpression.arguments {
            _ = try walk(argument)
        }
        if functionCallExpression.functionName == "print" {
            return .none
        } else {
            let lookupResult = lookupScope.lookup(functionCallExpression.functionName)
            guard let functionDeclaration = lookupResult as? FunctionDeclaration else {
                throw CompilationError(sourceRange: functionCallExpression.sourceRange,
                                       errorMessage: "Only functions can be called")
            }
            return functionDeclaration.returnType
        }
    }

    func visit(variableDeclaration: VariableDeclaration) throws -> Type {
        lookupScope.add(variableDeclaration)
        return .none
    }

    func visit(functionDeclaration: FunctionDeclaration) throws -> Type {
        lookupScope.add(functionDeclaration)
        lookupScope = LookupScope(previousScope: lookupScope)
        for parameter in functionDeclaration.parameters {
            try walk(parameter)
        }
        try walk(functionDeclaration.body)
        lookupScope = lookupScope.previousScope!

        return .none
    }

    func visit(astRoot: ASTRoot) throws -> Type {
        for statement in astRoot.statements {
            _ = try walk(statement)
        }
        return .none
    }
}
