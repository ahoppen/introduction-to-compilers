/// Enum containing all the possible optimisation options that can be applied
/// by the optimiser
public struct OptimisationOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Evaluate constant expressions.
    /// For example
    /// ```
    /// add 1, 2 -> %1
    /// ```
    /// becomes
    /// ```
    /// load 3 -> %1
    /// ```
    public static let constantExprssionEvaluation = OptimisationOptions(rawValue: 1 << 0)
    /// Propagate constants into instructions. For example replace
    ///
    /// ```
    /// load 1 -> %1
    /// add %1, 2 -> %2
    /// ```
    /// by 
    /// ```
    /// load 1 -> %1
    /// add 1, 2 -> %2
    /// ```
    public static let constantPropagation = OptimisationOptions(rawValue: 1 << 1)
    /// Remove instructions that store to registers that are never read
    public static let deadStoreElimination = OptimisationOptions(rawValue: 1 << 2)
    /// Remove instructions after `jump`, `return`, or `branch` instructions
    public static let deadCodeElimination = OptimisationOptions(rawValue: 1 << 3)
    /// Remove block that only contain a `jump` instruction by redirecting jumps or branches to that
    /// block to the `jump`'s target.
    ///
    /// For example:
    /// ```
    /// Start block: b0
    /// b0:
    ///   jump b1
    /// b1:
    ///   ...
    /// ```
    /// gets replace by
    /// ```
    /// Start block: b1
    /// b1:
    ///   ...
    /// ```
    public static let emptyBlockElimination = OptimisationOptions(rawValue: 1 << 4)
    /// Replace `jump` instructions with the block the `jump` jumps to.
    ///
    /// For example:
    /// ```
    /// b0:
    ///   ...
    ///   jump b1
    /// b1:
    ///   load "abc" -> %1
    ///   call print(%1) -> %2
    ///   return true
    /// ```
    /// gets replace by
    /// ```
    /// b0:
    ///   ...
    ///   load "abc" -> %1
    ///   call print(%1) -> %2
    ///   return true
    /// b1:
    ///   load "abc" -> %1
    ///   call print(%1) -> %2
    ///   return true
    /// ```
    public static let inlineJumpTargets = OptimisationOptions(rawValue: 1 << 5)
    /// Remove blocks that are never jumped or branched to
    public static let deadBlockElimination = OptimisationOptions(rawValue: 1 << 6)

    public static let all: OptimisationOptions = [.constantExprssionEvaluation,
                                                  .constantPropagation,
                                                  .deadStoreElimination,
                                                  .deadCodeElimination,
                                                  .emptyBlockElimination,
                                                  .inlineJumpTargets,
                                                  .deadBlockElimination]
}

/// The optimiser translates IR into a different IR with the same semantics by 
/// applying transformations that will speed up execution.
public class Optimiser {

    private let options: OptimisationOptions

    // MARK: - Public interface

    /// - Parameter options: The optimisation options to apply
    public init(options: OptimisationOptions) {
        self.options = options
    }

    public static func optimise(irFunction ir: IRFunction, withOptions options: OptimisationOptions) -> IRFunction {
        let optimiser = Optimiser(options: options)
        return optimiser.optimise(irFunction: ir)
    }

    public func optimise(ir: IR) -> IR {
        var optimisedFunctions: [String: IRFunction] = [:]
        for (name, function) in ir.functions {
            optimisedFunctions[name] = self.optimise(irFunction: function)
        }
        return IR(functions: optimisedFunctions)
    }

    /// Optimise the given IR function with the optimisation options this optimiser was
    /// initialised with
    ///
    /// - Parameter ir: The ir function to optimise
    /// - Returns: The optimised compilation result
    public func optimise(irFunction ir: IRFunction) -> IRFunction {
        var optimisedBlocks: [BlockName: [IRInstruction]] = [:]
        for (blockName, instructions) in ir.blocks {
            optimisedBlocks[blockName] = peepholeOptimise(block: instructions)
        }
        var optimised = IRFunction(startBlock: ir.startBlock, blocks: optimisedBlocks, argumentRegisters: ir.argumentRegisters)

        if options.contains(.deadCodeElimination) {
            optimised = eliminateDeadCode(in: optimised)
        }
        if options.contains(.deadStoreElimination) {
            optimised = eliminateDeadStores(in: optimised)
        }
        if options.contains(.emptyBlockElimination) {
            optimised = eliminateEmptyBlocks(in: optimised)
        }
        if options.contains(.inlineJumpTargets) {
            optimised = inlineJumpTargets(in: optimised)
        }
        if options.contains(.deadBlockElimination) {
            optimised = eliminateDeadBlocks(in: optimised)
        }
        return optimised
    }

    // MARK: - Private

    // MARK: Peephole optimisation

    /// Run peephole optimisation on the given instruction block. This evaluated constant 
    /// expressions and propagates constants if the corresponding options are enabled
    ///
    /// - Parameter block: The block to optimise
    /// - Returns: The optimised block
    private func peepholeOptimise(block: [IRInstruction]) -> [IRInstruction] {
        if block.isEmpty {
            return block
        }
        var optimisedBlock: [IRInstruction] = block

        var currentInstructionIndex = 0
        while currentInstructionIndex < optimisedBlock.count {
            while true {
                let previousInstruction: IRInstruction?
                if currentInstructionIndex > 0 {
                    previousInstruction = optimisedBlock[currentInstructionIndex - 1]
                } else {
                    previousInstruction = nil
                }

                let currentInstruction = optimisedBlock[currentInstructionIndex]

                guard let optimisedInstruction = peepholeOptimise(previousInstruction: previousInstruction, currentInstruction: currentInstruction) else {
                    break
                }
                optimisedBlock[currentInstructionIndex] = optimisedInstruction
            }
            currentInstructionIndex += 1
        }

        return optimisedBlock
    }

    /// Run a sing peephole optimisation step
    ///
    /// - Parameters:
    ///   - previousInstruction: The previous instruction if the current instruction is not the 
    ///                          first in the block
    ///   - currentInstruction: The current instruction
    /// - Returns: A new instruction that replaces the current instruction if the current 
    ///            instruction could be optimised or `nil` if no optimisation was performed
    private func peepholeOptimise(previousInstruction: IRInstruction?,
                                  currentInstruction: IRInstruction) -> IRInstruction? {

        // Optimisation only operating on the currentInstruction

        if options.contains(.constantExprssionEvaluation) {
            // Addition of two constants
            if case .add(.integer(let lhs), .integer(let rhs), let destination) = currentInstruction {
                return .load(value: .integer(lhs + rhs), destination: destination)
            }

            // Eliminate constant compares
            if case .equal(.integer(let lhs), .integer(let rhs), let destination) = currentInstruction {
                return .load(value: .boolean(lhs == rhs), destination: destination)
            }

            // Eliminate constant branches
            if case .branch(.boolean(let check), let trueBlock, let falseBlock) = currentInstruction {
                return .jump(toBlock: check ? trueBlock : falseBlock)
            }
        }

        // Optimisation taking into account the last instruction

        guard let lastInstruction = previousInstruction else {
            return nil
        }

        if options.contains(.constantPropagation) {
            // Propagate constant into add on lhs
            if case .add(.register(let lhs), let rhs, let destination) = currentInstruction,
                case .load(value: .integer(let lhsValue), destination: lhs) = lastInstruction {
                return .add(lhs: .integer(lhsValue), rhs: rhs, destination: destination)
            }
            // Propagate constant into add on rhs
            if case .add(let lhs, .register(let rhs), let destination) = currentInstruction,
                case .load(value: .integer(let rhsValue), destination: rhs) = lastInstruction {
                return .add(lhs: lhs, rhs: .integer(rhsValue), destination: destination)
            }

            // Propagate constant into compare on lhs
            if case .equal(.register(let lhs), let rhs, let destination) = currentInstruction,
                case .load(value: .integer(let lhsValue), destination: lhs) = lastInstruction {
                return .equal(lhs: .integer(lhsValue), rhs: rhs, destination: destination)
            }
            // Propagate constant into compare on rhs
            if case .equal(let lhs, .register(let rhs), let destination) = currentInstruction,
                case .load(value: .integer(let rhsValue), destination: rhs) = lastInstruction {
                return .equal(lhs: lhs, rhs: .integer(rhsValue), destination: destination)
            }

            // Propagate constant into branch
            if case .branch(.register(let check), let trueBlock, let falseBlock) = currentInstruction,
                case .load(value: .boolean(let value), destination: check) = lastInstruction {
                return .branch(check: .boolean(value), trueBlock: trueBlock, falseBlock: falseBlock)
            }
        }

        return nil
    }

    // MARK: Empty block elimination

    /// Eliminate block only containting a `jump` by redirecting `jump`s or `branch`es to this block
    /// to that block's jump target
    ///
    /// - Parameter ir: The IR function to optimise
    /// - Returns: The optimised IR function without block just containing `jump`s
    private func eliminateEmptyBlocks(in ir: IRFunction) -> IRFunction {
        var result = ir
        for (blockName, instructions) in result.blocks {
            var replacement: (BlockName, BlockName)? = nil
            if instructions.count == 1 {
                if case .jump(let toBlock) = instructions.first! {
                    replacement = (blockName, toBlock)
                }
            }
            if let (replaceBlock, replaceBy) = replacement {
                result = redirectJumps(from: replaceBlock, to: replaceBy, in: result)
            }
        }
        return result
    }

    /// Redirect all jumps from `source` to `destination` in the given compilation result
    ///
    /// - Parameters:
    ///   - source: `jump`s to this block shall be redirected
    ///   - destination: The new destination where the `jump`s should point
    ///   - ir: The IR function to optimise
    /// - Returns: The optimised IR function
    private func redirectJumps(from source: BlockName, to destination: BlockName, in ir: IRFunction) -> IRFunction {
        func performReplacement(_ block: BlockName) -> BlockName {
            if block == source {
                return destination
            } else {
                return block
            }
        }

        var resultBlocks: [BlockName: [IRInstruction]] = [:]

        for (blockName, instructions) in ir.blocks {
            var resultIntructions: [IRInstruction] = []
            for instruction in instructions {
                switch instruction {
                case .branch(let check, let trueBlock, let falseBlock):
                    resultIntructions.append(.branch(check: check,
                                                     trueBlock: performReplacement(trueBlock),
                                                     falseBlock: performReplacement(falseBlock)))
                case .jump(let toBlock):
                    resultIntructions.append(.jump(toBlock: performReplacement(toBlock)))
                default:
                    resultIntructions.append(instruction)
                }
            }
            resultBlocks[blockName] = resultIntructions
        }

        return IRFunction(startBlock: performReplacement(ir.startBlock), blocks: resultBlocks, argumentRegisters: ir.argumentRegisters)
    }

    // MARK: Dead code elimination

    /// Eliminate instructions after `branch`, `jump`, or `return`
    ///
    /// - Parameter ir: The IR function to optimise
    /// - Returns: The optimised IR function
    private func eliminateDeadCode(in ir: IRFunction) -> IRFunction {
        var result: [BlockName: [IRInstruction]] = [:]
        for (blockName, instructions) in ir.blocks {
            var resultInstructions: [IRInstruction] = []

            instructionsLoop: for instruction in instructions {
                switch instruction {
                case .jump(_), .branch(_), .return(_):
                    resultInstructions.append(instruction)
                    break instructionsLoop
                default:
                    resultInstructions.append(instruction)
                }
            }

            result[blockName] = resultInstructions
        }

        return IRFunction(startBlock: ir.startBlock, blocks: result, argumentRegisters: ir.argumentRegisters)
    }

    // MARK: Dead store elimination

    /// Eliminate instructions that write to registers that are never read
    ///
    /// - Parameter ir: The IR function to optimise
    /// - Returns: The optimised IR function
    private func eliminateDeadStores(in ir: IRFunction) -> IRFunction {
        var blocks = ir.blocks
        while true {
            let usedRegisters = determineUsedRegisters(inBlocks: blocks)
            let (changed, optimisedBlocks) = removeInstructions(assigningRegistersNotIn: usedRegisters,
                                                                inBlocks: blocks)
            if !changed {
                return IRFunction(startBlock: ir.startBlock, blocks: blocks, argumentRegisters: ir.argumentRegisters)
            } else {
                blocks = optimisedBlocks
            }
        }
    }

    /// Determine the registers whose values are ever read
    ///
    /// - Parameter blocks: The blocks to analyse
    /// - Returns: The registers whose value is read in any of the blocks
    private func determineUsedRegisters(inBlocks blocks: [BlockName: [IRInstruction]]) -> [Register] {
        var usedRegisters: [Register] = []

        func use(irValue: IRValue) {
            if case .register(let register) = irValue {
                usedRegisters.append(register)
            }
        }

        for (_, instructions) in blocks {
            for instruction in instructions {
                switch instruction {
                case .add(let lhs, let rhs, _):
                    use(irValue: lhs)
                    use(irValue: rhs)
                case .equal(let lhs, let rhs, _):
                    use(irValue: lhs)
                    use(irValue: rhs)
                case .branch(let check, _, _):
                    use(irValue: check)
                case .call(_, let arguments, _):
                    for argument in arguments {
                        use(irValue: argument)
                    }
                case .return(returnValue: let returnValue):
                    use(irValue: returnValue)
                default:
                    break
                }
            }
        }

        return usedRegisters
    }

    /// Remove all instructions in the given blocks that assign registers not in 
    /// `assigningRegistersNotIn`
    ///
    /// - Parameters:
    ///   - assigningRegistersNotIn: Remove all instructions assigning registers that are not in 
    ///                              this list
    ///   - blocks: The blocks in which instructions shall be removed
    /// - Returns: A tuple `(changed, blocks)`. `changed` is true if any instruction was removed
    ///            `blocks` contains the blocks in which instructions were removed as described above
    private func removeInstructions(assigningRegistersNotIn: [Register],
                                    inBlocks blocks: [BlockName: [IRInstruction]]) -> (Bool, [BlockName: [IRInstruction]]) {
        var result: [BlockName: [IRInstruction]] = [:]
        var changed = false
        for (blockName, instructions) in blocks {
            var resultInstructions: [IRInstruction] = []

            for instruction in instructions {
                switch instruction {
                case .add(_, _, let destination) where !assigningRegistersNotIn.contains(destination):
                    changed = true
                    break
                case .equal(_, _, let destination) where !assigningRegistersNotIn.contains(destination):
                    changed = true
                    break
                case .load(_, let destination) where !assigningRegistersNotIn.contains(destination):
                    changed = true
                    break
                default:
                    resultInstructions.append(instruction)
                }
            }

            result[blockName] = resultInstructions
        }

        return (changed, result)
    }

    // MARK: Dead block elimination

    /// Remove all blocks that are not the start block and that are never jumped to
    ///
    /// - Parameter ir: The IR function in which dead blocks shall be removed
    /// - Returns: The optimised IR function
    private func eliminateDeadBlocks(in ir: IRFunction) -> IRFunction {
        var optimisedBlocks = ir.blocks

        while true {
            var usedBlocks: Set<BlockName> = [ir.startBlock]
            for (_, instructions) in optimisedBlocks {
                for instruction in instructions {
                    switch instruction {
                    case .branch(_, let trueBlock, let falseBlock):
                        usedBlocks.insert(trueBlock)
                        usedBlocks.insert(falseBlock)
                    case .jump(let toBlock):
                        usedBlocks.insert(toBlock)
                    default:
                        break
                    }
                }
            }

            let blocksToRemove = Set(optimisedBlocks.keys).subtracting(usedBlocks)
            if blocksToRemove.isEmpty {
                break
            } else {
                for toRemove in blocksToRemove {
                    optimisedBlocks[toRemove] = nil
                }
            }
        }

        return IRFunction(startBlock: ir.startBlock, blocks: optimisedBlocks, argumentRegisters: ir.argumentRegisters)
    }

    // MARK: Jump target inlining

    /// Eliminate `jump`s by replacing the `jump` instruction with the block the `jump` jumps to.
    ///
    /// This asssumes that there are no loops in the programs. Otherwise this method may not
    /// terminate
    ///
    /// - Parameter ir: The IR function to optimise
    /// - Returns: The optimised compilation result
    private func inlineJumpTargets(in ir: IRFunction) -> IRFunction {
        var resultBlocks: [BlockName: [IRInstruction]] = [:]
        for (blockName, _) in ir.blocks {
            resultBlocks[blockName] = inlineJumpTargets(in: blockName, ir: ir)
        }
        return IRFunction(startBlock: ir.startBlock, blocks: resultBlocks, argumentRegisters: ir.argumentRegisters)
    }

    /// Eliminate `jump`s in this block by replacing the `jump` instruction with the block the 
    /// `jump` jumps to.
    /// 
    /// This asssumes that there are no loops in the programs. Otherwise this method may not
    /// terminate
    ///
    /// - Parameters:
    ///   - block: The block in which `jump` shall be eliminated
    ///   - ir: The IR function that specifies the other blocks
    /// - Returns: A block semantically equivalent to `block` but without `jump`s
    private func inlineJumpTargets(in block: BlockName, ir: IRFunction) -> [IRInstruction] {
        var result: [IRInstruction] = []
        for instruction in ir.blocks[block]! {
            switch instruction {
            case .jump(let toBlock):
                result += inlineJumpTargets(in: toBlock, ir: ir)
            default:
                result.append(instruction)
            }
        }
        return result
    }
}
