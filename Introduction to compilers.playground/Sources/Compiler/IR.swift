import Cocoa

/// A register whose value can be loaded and to whcih values can be stored in the IR
public struct Register: Hashable, CustomStringConvertible {
    public let name: Int

    init(name: Int) {
        self.name = name
    }

    public static func ==(lhs: Register, rhs: Register) -> Bool {
        return lhs.name == rhs.name
    }

    public var hashValue: Int {
        return name.hashValue
    }

    public var description: String {
        return "%\(name)"
    }
}

/// The name uniquely identifying a basic block in the IR. This name will be used to jump to a block
/// using `jump` or `branch`
public struct BlockName: Hashable, CustomStringConvertible {
    public let name: Int

    public init(name: Int) {
        self.name = name
    }

    public static func ==(lhs: BlockName, rhs: BlockName) -> Bool {
        return lhs.name == rhs.name
    }

    public var hashValue: Int {
        return name.hashValue
    }

    public var description: String {
        return "b\(name)"
    }
}

/// The different kinds of values, arguments in the IR can take
///
/// - register: Retrieve the value from a specified register
/// - integer: A constant register argument
/// - boolean: A constant boolean argument
/// - string: A constant string argument
public enum IRValue: CustomStringConvertible {
    case register(Register)
    case integer(Int)
    case boolean(Bool)
    case string(String)

    public var description: String {
        switch self {
        case .register(let register):
            return register.description
        case .integer(let value):
            return "\(value)"
        case .boolean(let value):
            return "\(value)"
        case .string(let value):
            return "\"\(value)\""
        }
    }
}

/// Instructions in the IR
public enum IRInstruction: CustomDebugStringConvertible {
    /// Add `lhs` and `rhs` and store the value to `destination`
    case add(lhs: IRValue, rhs: IRValue, destination: Register)
    /// Subtract `rhs` from `lhs` and store the value to `destination`
    case sub(lhs: IRValue, rhs: IRValue, destination: Register)
    /// Set `destination` to `true` if `lhs == rhs` and to `false` otherwise
    case equal(lhs: IRValue, rhs: IRValue, destination: Register)
    /// Set `destination` to `true` if `lhs <= rhs` and to `false` otherwise
    case lessOrEqual(lhs: IRValue, rhs: IRValue, destination: Register)
    /// Jump to `trueBlock` if `check` is `true` and to `falseBlock` otherwise
    case branch(check: IRValue, trueBlock: BlockName, falseBlock: BlockName)
    /// Jump to `toBlock`
    case jump(toBlock: BlockName)
    /// Call function with name `functionName` with `argument` and store the result in `destination`
    case call(functionName: String, arguments: [IRValue], destination: Register)
    /// Load the constant `value` into `destination`
    case load(value: IRValue, destination: Register)
    /// Finish execution of the program
    case `return`(returnValue: IRValue)

    public var debugDescription: String {
        switch self {
        case let .add(lhs, rhs, destination):
            return "add \(lhs), \(rhs) -> \(destination)"
        case let .sub(lhs, rhs, destination):
            return "sub \(lhs), \(rhs) -> \(destination)"
        case let .equal(lhs, rhs, destination):
            return "equal \(lhs), \(rhs) -> \(destination)"
        case let .lessOrEqual(lhs, rhs, destination):
            return "lessOrEqual \(lhs), \(rhs) -> \(destination)"
        case let .branch(check, trueBlock, falseBlock):
            return "branch \(check), true: \(trueBlock), false: \(falseBlock)"
        case let .jump(toBlock):
            return "jump \(toBlock)"
        case let .call(text, arguments, destination):
            let args = arguments.map({ $0.description }).joined(separator: ", ")
            return "call \(text)(\(args)) -> \(destination)"
        case let .load(value, destination):
            return "load \(value) -> \(destination)"
        case .return(let value):
            return "return \(value)"
        }
    }
}

/// A program in the compiler's IR, consisting of the IR's basic blocks and the block in which to
/// start execution
public struct IRFunction: CustomDebugStringConvertible, CustomPlaygroundQuickLookable {
    public let startBlock: BlockName
    public let blocks: [BlockName: [IRInstruction]]
    public let argumentRegisters: [Register]

    public var debugDescription: String {
        var result = "Start block: \(startBlock)\n\n"

        for blockName in blocks.keys.sorted(by: { $0.name < $1.name }) {
            let instructions = blocks[blockName]!
            result += "\(blockName):\n"
            for instruction in instructions {
                result += "  " + instruction.debugDescription + "\n"
            }
        }
        return result
    }

    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        return .attributedString(self.debugDescription.monospacedString.withPlaygroundQuickLookBackgroundColor)
    }
}

public struct IR: CustomDebugStringConvertible, CustomPlaygroundQuickLookable {
    public let functions: [String: IRFunction]

    public var debugDescription: String {
        var result = ""
        for functionName in functions.keys {
            let function = functions[functionName]!
            result += functionName + "("
            result += function.argumentRegisters.map({ $0.description }).joined(separator: ", ")
            result += "): \n"
            result += function.debugDescription.components(separatedBy: "\n").map({ "  " + $0 }).joined(separator: "\n")
            result += "\n"
        }
        return result
    }

    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        return .attributedString(self.debugDescription.monospacedString.withPlaygroundQuickLookBackgroundColor)
    }
}
