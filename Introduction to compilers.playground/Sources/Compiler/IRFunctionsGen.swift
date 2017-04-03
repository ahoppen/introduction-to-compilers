public class IRFunctionGen: ASTWalker {
    typealias Result = IRValue?

    /// The lowest id so that no register with this ID has been created yet
    private var _nextFreeRegisterId = 1

    /// Returns a register that hasn't been used yet, incrementing the `_nextFreeRegisterId` counter
    ///
    /// - Returns: A register that hasn't been used yet
    private func nextFreeRegister() -> Register {
        defer { _nextFreeRegisterId += 1 }
        return Register(name: _nextFreeRegisterId)
    }

    /// The name of the block that is currently beeing generated
    private var currentBlockName = BlockName(name: 0)

    /// The lowest name so that no block with this name has been created yet
    private var _nextFreeBlockName = 1

    /// Returns a block name that hasn't been used yet, incrementing the `_nextFreeBlockName` counter
    ///
    /// - Returns: A block that hasn't been used yet
    private func nextFreeBlock() -> BlockName {
        defer { _nextFreeBlockName += 1 }
        return BlockName(name: _nextFreeBlockName)
    }

    /// The block that is currently being created
    private var currentBlock: [IRInstruction] = []

    /// A collection of blocks that have been finished generating
    private var finishedBlocks: [BlockName: [IRInstruction]] = [:]

    private var variables: [VariableDeclaration: Register] = [:]

    private var argumentRegisters: [Register] = []

    // MARK: - Public Methods

    public init() {
    }

    /// Generate the IR for the given AST
    ///
    /// - Parameter astRoot: The AST for which to create IR code
    /// - Returns: The generated IR
    public static func generateIR(forAST astNode: ASTNode) -> IRFunction {
        return IRFunctionGen().generateIR(forAST: astNode)
    }

    /// Generate the IR for the given AST
    ///
    /// - Parameter astRoot: The AST for which to create IR code
    /// - Returns: The generated IR
    public func generateIR(forAST astNode: ASTNode) -> IRFunction {
        let mainBlock = currentBlockName
        _ = walk(astNode)

        finishedBlocks[currentBlockName] = currentBlock

        return IRFunction(startBlock: mainBlock, blocks: finishedBlocks, argumentRegisters: argumentRegisters)
    }

    // MARK: Private helper methods

    /// Add the given instruction to the current block
    ///
    /// - Parameter instruction: The instruction to add to the current block
    private func emit(instruction: IRInstruction) {
        currentBlock.append(instruction)
    }

    /// Add the current block to the list of finished blocks by assigning it the given name and
    /// clear the `currentBlock` buffer.
    ///
    /// - Parameter withName: The name to assign the current block
    private func finishCurrentBlock(withName: BlockName) {
        finishedBlocks[withName] = currentBlock
        currentBlock = []
    }

    // MARK: ASTWalker

    func visit(ifStatement: IfStatement) -> Result {
        let trueBlock = nextFreeBlock()
        let falseBlock = nextFreeBlock()
        // Short circuit the falsBlock to the restBlock if the if statement has no else body
        let restBlock = ifStatement.elseBody != nil ? nextFreeBlock() : falseBlock

        let conditionValue = walk(ifStatement.condition)
        emit(instruction: .branch(check: conditionValue!,
                                  trueBlock: trueBlock,
                                  falseBlock: falseBlock))
        finishCurrentBlock(withName: currentBlockName)

        _ = walk(ifStatement.body)
        emit(instruction: .jump(toBlock: restBlock))
        finishCurrentBlock(withName: trueBlock)

        if let elseBody = ifStatement.elseBody {
            _ = walk(elseBody)
            emit(instruction: .jump(toBlock: restBlock))
            finishCurrentBlock(withName: falseBlock)
        }

        currentBlockName = restBlock

        return nil
    }

    func visit(braceStatement: BraceStatement) -> Result {
        for statement in braceStatement.body {
            _ = walk(statement)
        }
        return nil
    }

    func visit(returnStatement: ReturnStatement) -> Result {
        let returnValue = walk(returnStatement.expression)!
        currentBlock.append(.return(returnValue: returnValue))
        return nil
    }

    func visit(binaryOperatorExpression: BinaryOperatorExpression) -> Result {
        let lhsValue = walk(binaryOperatorExpression.lhs)
        let rhsValue = walk(binaryOperatorExpression.rhs)
        let destination = nextFreeRegister()

        switch binaryOperatorExpression.operator {
        case .add:
            emit(instruction: .add(lhs: lhsValue!, rhs: rhsValue!, destination: destination))
            return IRValue.register(destination)
        case .sub:
            emit(instruction: .sub(lhs: lhsValue!, rhs: rhsValue!, destination: destination))
            return IRValue.register(destination)
        case .equal:
            emit(instruction: .equal(lhs: lhsValue!, rhs: rhsValue!, destination: destination))
            return IRValue.register(destination)
        case .lessOrEqual:
            emit(instruction: .lessOrEqual(lhs: lhsValue!, rhs: rhsValue!, destination: destination))
            return IRValue.register(destination)
        }
    }

    func visit(integerLiteralExpression: IntegerLiteralExpression) -> Result {
        return .integer(integerLiteralExpression.value)
    }

    func visit(stringLiteralExpression: StringLiteralExpression) -> Result {
        let destination = nextFreeRegister()
        emit(instruction: .load(value: .string(stringLiteralExpression.value), destination: destination))
        return .register(destination)
    }

    func visit(identifierReferenceExpression: IdentifierReferenceExpression) -> Result {
        let referencedVariable = identifierReferenceExpression.referencedDeclaration! as! VariableDeclaration
        return .register(variables[referencedVariable]!)
    }

    func visit(functionCallExpression: FunctionCallExpression) -> Result {
        let destination = nextFreeRegister()
        let arguments = functionCallExpression.arguments.map({ walk($0)! })
        emit(instruction: .call(functionName: functionCallExpression.functionName, arguments: arguments, destination: destination))
        return .register(destination)
    }

    func visit(variableDeclaration: VariableDeclaration) -> Result {
        let register = nextFreeRegister()
        variables[variableDeclaration] = register
        return .register(register)
    }

    func visit(functionDeclaration: FunctionDeclaration) -> Result {
        for parameter in functionDeclaration.parameters {
            guard case .register(let argumentRegister) = walk(parameter)! else {
                fatalError()
            }
            argumentRegisters.append(argumentRegister)
        }
        _ = walk(functionDeclaration.body)
        return nil
    }

    
    func visit(astRoot: ASTRoot) -> Result {
        for statement in astRoot.statements {
            if !(statement is FunctionDeclaration) {
                _ = walk(statement)
            }
        }
        currentBlock.append(.return(returnValue: .boolean(true)))
        return nil
    }
    
}
