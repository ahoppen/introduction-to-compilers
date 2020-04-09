/// A node in the source codes abstract syntax tree (AST)
public class ASTNode: CustomDebugStringConvertible, CustomPlaygroundDisplayConvertible {
    /// The range in the source code which this node represents
    public let sourceRange: SourceRange

    public var debugDescription: String {
        let printer = ASTPrinter()
        printer.print(self)
        return printer.output
    }

    public var playgroundDescription: Any {
        return debugDescription.monospacedString.withPlaygroundQuickLookBackgroundColor
    }

    init(sourceRange: SourceRange) {
        self.sourceRange = sourceRange
    }
}

/// Represents a source file with its statements
public class ASTRoot: ASTNode {
    public let statements: [Statement]

    init(statements: [Statement], sourceRange: SourceRange) {
        self.statements = statements
        super.init(sourceRange: sourceRange)
    }
}

/// Abstract base class for statements in the AST
///
/// Statements do not return values whereas expresions do
public class Statement: ASTNode {
}

/// An if statement in the AST
public class IfStatement: Statement {
    /// The condition to be evaluated to decide if the statement's body shall
    /// be executed
    public let condition: Expression
    /// The body to be executed only if the condition evaluates to true
    public let body: BraceStatement
    /// The body of the else-clause if it existed
    public let elseBody: BraceStatement?
    /// The source range of the `if` keyword
    public let ifRange: SourceRange
    /// The source range of the `else` keyword if it existed
    public let elseRange: SourceRange?

    /// Create a node in the AST representing an `if` statement
    ///
    /// - Parameters:
    ///   - condition: The condition to evaluate in order to determine if the if body shall be executed
    ///   - body: The body of the `if` statement
    ///   - elseBody: If the else statment has an `else` part, its body, otherwise `nil`
    ///   - ifRange: The source range of the `if` keyword
    ///   - elseRange: The source range of the `else` keyword, if present
    ///   - sourceRange: The source range of the entire statement
    public init(condition: Expression, body: BraceStatement, elseBody: BraceStatement?, ifRange: SourceRange, elseRange: SourceRange?, sourceRange: SourceRange) {
        self.condition = condition
        self.body = body
        self.elseBody = elseBody
        self.ifRange = ifRange
        self.elseRange = elseRange
        super.init(sourceRange: sourceRange)
    }
}

/// A brace statement is a block of other statements combined using '{' and '}'
public class BraceStatement: Statement {
    /// The statements this brace statement contains
    public let body: [Statement]

    init(body: [Statement], sourceRange: SourceRange) {
        self.body = body
        super.init(sourceRange: sourceRange)
    }
}

/// A return statement starting with `return`
public class ReturnStatement: Statement {
    /// The expression whose value shall be returned
    public let expression: Expression

    init(expression: Expression, sourceRange: SourceRange) {
        self.expression = expression
        super.init(sourceRange: sourceRange)
    }
}

/// Abstract base class for expresions in the AST
/// 
/// In contrast to statements, expressions calculate values
public class Expression: Statement {
}

/// A binary operator expression combines the value two expressions using an infix 
/// operator like '+' or '=='
public class BinaryOperatorExpression: Expression {

    /// Enumeration of all the binary operators supported by the BinaryOperatorExpression
    public enum Operator {
        case add
        case sub
        case equal
        case lessOrEqual

        /// The name with which this operator is spellec out in the source code
        public var sourceCodeName: String {
            switch self {
            case .add:
                return "+"
            case .sub:
                return "-"
            case .equal:
                return "=="
            case .lessOrEqual:
                return "<="
            }
        }

        /// The precedence of the operator, e.g. '*' has higher precedence than '+'.
        ///
        /// A higher precedence value means that the value should bind stronger than 
        /// values with lower precedence
        var precedence: Int {
            switch self {
            case .add:
                return 2
            case .sub:
                return 2
            case .equal:
                return 1
            case .lessOrEqual:
                return 1
            }
        }
    }

    /// The left-hand-side of the operator
    public let lhs: Expression
    /// The right-hand-side of the operator
    public let rhs: Expression
    /// The operator to combine the two expressions
    public let `operator`: Operator

    init(lhs: Expression, rhs: Expression, operator: Operator) {
        self.lhs = lhs
        self.rhs = rhs
        self.operator = `operator`
        let sourceRange = SourceRange(start: self.lhs.sourceRange.start,
                                      end: self.rhs.sourceRange.end)
        super.init(sourceRange: sourceRange)
    }
}

/// A constant integer spelled out in the source code like '42'
public class IntegerLiteralExpression: Expression {
    /// The value of the literal
    public let value: Int

    init(value: Int, sourceRange: SourceRange) {
        self.value = value
        super.init(sourceRange: sourceRange)
    }
}

/// A constant string spelled out in the source code like 'hello world'
public class StringLiteralExpression: Expression {
    /// The value of the literal
    public let value: String

    init(value: String, sourceRange: SourceRange) {
        self.value = value
        super.init(sourceRange: sourceRange)
    }
}

public class IdentifierReferenceExpression: Expression {
    /// The name of the referenced identifier
    public let name: String
    public var referencedDeclaration: Declaration?

    init(name: String, sourceRange: SourceRange) {
        self.name = name
        super.init(sourceRange: sourceRange)
    }
}

/// Call of a function with a single argument
/// 
/// This is currently only used to model the 'print' function
public class FunctionCallExpression: Expression {
    /// The name of the function to call
    public let functionName: String
    /// The arguments to pass on the function call
    public let arguments: [Expression]
    /// The source range of the function name
    public let functionNameRange: SourceRange

    init(functionName: String, arguments: [Expression], functionNameRange: SourceRange, sourceRange: SourceRange) {
        self.functionName = functionName
        self.arguments = arguments
        self.functionNameRange = functionNameRange
        super.init(sourceRange: sourceRange)
    }
}


/// Abstract base class for declarations like functions or function arguments
public class Declaration: Statement {
    /// The type of the declaration
    let type: Type

    init(type: Type, sourceRange: SourceRange) {
        self.type = type
        super.init(sourceRange: sourceRange)
    }
}

/// Declaration of a function's argument
public class VariableDeclaration: Declaration, Hashable {
    /// The name of the variable
    public let name: String
  
  
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
    }

    init(name: String, type: Type, sourceRange: SourceRange) {
        self.name = name
        super.init(type: type, sourceRange: sourceRange)
    }

    public static func ==(lhs: VariableDeclaration, rhs: VariableDeclaration) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type
    }
}

/// A function declaration
public class FunctionDeclaration: Declaration {
    /// The function's name
    public let name: String
    /// The parameters the function takes
    public let parameters: [VariableDeclaration]
    /// The name of the function's return type
    public let returnType: Type
    /// The function's body
    public let body: BraceStatement

    public init(name: String, parameters: [VariableDeclaration], returnType: Type, body: BraceStatement, sourceRange: SourceRange) {
        self.name = name
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
        super.init(type: .function, sourceRange: sourceRange)
    }
}
