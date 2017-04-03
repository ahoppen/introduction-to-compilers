public struct StackFrame {
    public fileprivate(set) var functionName: String
    public fileprivate(set) var block: BlockName
    public internal(set) var instructionIndex: Int = 0
    public fileprivate(set) var registers: [Register: IRValue] = [:]
    public fileprivate(set) var functionCallDestinationRegister: Register?

    init(functionName: String, block: BlockName) {
        self.functionName = functionName
        self.block = block
    }
}

/// Class that can execute the IR
public class IRExecutor {
    /// The values that the different registers currently hold
    var callStack: [StackFrame]

    private var ir: IR

    public init(ir: IR) {
        self.ir = ir
        callStack = [StackFrame(functionName: "main", block: ir.functions["main"]!.startBlock)]
    }

    /// Execute the given IR
    ///
    /// - Parameter ir: The IR to execute
    public func execute() {
        while !callStack.isEmpty {
            executeNextStep()
        }
    }

    public func executeNextStep() {
        if callStack.isEmpty {
            return
        }
        let currentBlock = self.ir.functions[callStack[0].functionName]!.blocks[callStack[0].block]!
        let currentInstruction = currentBlock[callStack[0].instructionIndex]
        execute(instruction: currentInstruction)
    }

    /// Print a string to the user
    ///
    /// - Parameter string: The string to print
    func output(_ string: String) {
        print(string)
    }

    /// Execute an instruction, updating the register values as needed and returning the next block
    /// to execute if it was a `branch`, `jump`, or `exit` instruction
    ///
    /// - Parameter instruction: The instruction to execute
    /// - Returns: The next block to execute if the instruction transfers control to a different block
    func execute(instruction: IRInstruction) {
        switch instruction {
        case let .add(lhs, rhs, destination):
            callStack[0].registers[destination] = .integer(evaluate(irValue: lhs) + evaluate(irValue: rhs))
            increaseProgramCounter()
        case let .sub(lhs, rhs, destination):
            callStack[0].registers[destination] = .integer(evaluate(irValue: lhs) - evaluate(irValue: rhs))
            increaseProgramCounter()
        case let .equal(lhs, rhs, destination):
            let value = evaluate(irValue: lhs) as Int == evaluate(irValue: rhs)
            callStack[0].registers[destination] = .boolean(value)
            increaseProgramCounter()
        case let .lessOrEqual(lhs, rhs, destination):
            let value = (evaluate(irValue: lhs) as Int) <= (evaluate(irValue: rhs) as Int)
            callStack[0].registers[destination] = .boolean(value)
            increaseProgramCounter()
        case let .branch(check, trueBlock, falseBlock):
            if evaluate(irValue: check) != 0 {
                jump(toBlock: trueBlock)
            } else {
                jump(toBlock: falseBlock)
            }
        case let .jump(toBlock):
            jump(toBlock: toBlock)
        case let .call(functionName, arguments, destination):
            if functionName == "print" {
                output(evaluate(irValue: arguments[0]))
                callStack[0].registers[destination] = .boolean(true)
                increaseProgramCounter()
            } else {
                let irFunction = ir.functions[functionName]!
                var stackFrame = StackFrame(functionName: functionName, block: irFunction.startBlock)

                assert(arguments.count == irFunction.argumentRegisters.count)
                for i in 0..<arguments.count {
                    stackFrame.registers[irFunction.argumentRegisters[i]] = .integer(evaluate(irValue: arguments[i]))
                }

                callStack[0].functionCallDestinationRegister = destination
                increaseProgramCounter()
                callStack.insert(stackFrame, at: 0)
            }
        case .load(let value, let destination):
            callStack[0].registers[destination] = value
            increaseProgramCounter()
        case .return(let returnValue):
            if callStack.count > 1 {
                callStack[1].registers[callStack[1].functionCallDestinationRegister!] = .integer(evaluate(irValue: returnValue))
            }
            callStack.remove(at: 0)
        }
    }

    /// Evaluate the given IR value as an integer. This looks up values in registers and 
    /// short-circuits literal values.
    ///
    /// Crashes if the type is not convertible to an integer.
    ///
    /// - Parameter irValue: The value
    /// - Returns: The `Int` value of the given `IRValue`
    private func evaluate(irValue: IRValue) -> Int {
        switch irValue {
        case .register(let register):
            if let registerValue = callStack[0].registers[register] {
                return evaluate(irValue: registerValue)
            } else {
                return 0
            }
        case .integer(let value):
            return value
        case .boolean(let value):
            return value ? 1 : 0
        default:
            fatalError("Cannot convert \(irValue) to int")
        }
    }

    /// Evaluate the given IR value as an string. This looks up values in registers and
    /// short-circuits literal values.
    ///
    /// - Parameter irValue: The value
    /// - Returns: The `String` value of the given `IRValue`
    private func evaluate(irValue: IRValue) -> String {
        switch irValue {
        case .register(let register):
            if let registerValue = callStack[0].registers[register] {
                return evaluate(irValue: registerValue)
            } else {
                return ""
            }
        case .integer(let value):
            return "\(value)"
        case .boolean(let value):
            return value ? "true" : "false"
        case .string(let string):
            return string
        }
    }

    private func jump(toBlock: BlockName) {
        callStack[0].block = toBlock
        callStack[0].instructionIndex = 0
    }

    private func increaseProgramCounter() {
        callStack[0].instructionIndex += 1
    }
}
