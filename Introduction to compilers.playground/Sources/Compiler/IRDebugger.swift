public struct DebuggerState {
    public let callStack: [StackFrame]
    public let currentFunctionName: String
    public let currentBlock: BlockName
    public let currentInstructionIndex: Int
    public let output: String
}

public class IRDebugger: IRExecutor {
 
    /// The output the program has produced so far
    private var output = ""

    public var debuggerState: DebuggerState? {
        if callStack.isEmpty {
            return nil
        } else {
            var adjustedCallStack: [StackFrame] = []
            adjustedCallStack.append(callStack[0])
            for i in 1..<callStack.count {
                var stackFrame = callStack[i]
                stackFrame.instructionIndex -= 1
                adjustedCallStack.append(stackFrame)
            }
            return DebuggerState(callStack: adjustedCallStack,
                                 currentFunctionName: callStack[0].functionName,
                                 currentBlock: callStack[0].block,
                                 currentInstructionIndex: callStack[0].instructionIndex,
                                 output: output)
        }
    }

    override func output(_ string: String) {
        self.output += string + "\n"
    }    
}
