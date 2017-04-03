import Cocoa

fileprivate class TableViewCell: NSTableCellView { 
    override var backgroundStyle: NSBackgroundStyle {
        didSet {
            let str = NSMutableAttributedString(attributedString: self.textField!.attributedStringValue)
            switch backgroundStyle {
            case .light:
                str.addAttribute(NSForegroundColorAttributeName,
                                 value: NSColor.black,
                                 range: NSRange(location: 0, length: str.length))
            case .dark:
                str.addAttribute(NSForegroundColorAttributeName,
                                 value: NSColor.white,
                                 range: NSRange(location: 0, length: str.length))
            default:
                break
            } 
            self.textField?.attributedStringValue = str
        }
    }
}

fileprivate class RegisterValuesDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var registerValues: [Register: IRValue] = [:]
    var sortedRegisterValues: [(Register, IRValue)] { 
        let sortedKeys = registerValues.keys.sorted(by: { $0.name < $1.name })
        return sortedKeys.map({ ($0, registerValues[$0]!) })
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return registerValues.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let (register, value) = sortedRegisterValues[row]

        let string = NSMutableAttributedString(string: "\(register) \(value)")
        string.addAttribute(NSFontAttributeName,
                            value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize()),
                            range: NSRange(location: 0, length: ("\(register)" as NSString).length))
        string.addAttribute(NSForegroundColorAttributeName,
                            value: NSColor.darkGray,
                            range: NSRange(location: ("\(register)" as NSString).length,
                                           length: (" \(value)" as NSString).length))

        let textView = NSTextField(labelWithAttributedString: string)
        let cell = TableViewCell()
        cell.textField = textView
        cell.addSubview(textView)
        return cell
    }
}

fileprivate class StackFramesDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var stackFrames: [StackFrame] = []
    var selectionDidChangeCallback: ((Int) -> Void)?

    func numberOfRows(in tableView: NSTableView) -> Int {
        return stackFrames.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let label = "#\(row): \(stackFrames[row].functionName)"
        let textView = NSTextField(labelWithString: label)
        let cell = TableViewCell()
        cell.textField = textView
        cell.addSubview(textView)
        return cell
    }

    fileprivate func tableViewSelectionDidChange(_ notification: Notification) {
        let tv = notification.object! as! NSTableView
        selectionDidChangeCallback?(tv.selectedRow)
    }

}

extension NSTouchBarItemIdentifier {
    static let stepItem = NSTouchBarItemIdentifier("Step")
    static let continueItem = NSTouchBarItemIdentifier("Continue")
    static let resetItem = NSTouchBarItemIdentifier("Reset")
}

func +=(lhs: NSMutableAttributedString, rhs: NSAttributedString) {
    lhs.append(rhs)
}

/// A UI for a debugger that is able to step through IR instructions
public class DebuggerView: NSSplitView, NSTouchBarDelegate {

    private var ir: IR?
    private var debugger: IRDebugger?
    private let irView = NSTextField()
    private let registerValuesView = NSTableView()
    private let registerValuesViewDataSource = RegisterValuesDataSource()
    private let stackFramesView = NSTableView()
    private let stackFramesDataSource = StackFramesDataSource()
    private let resultsView = NSTextField()
    private let footerView = NSSplitView()
    private var callStack: [StackFrame] = []

    /// - Parameter sourceFile: The source file whose IR to debug
    public init(forSourceFile sourceFile: SwiftFile) {
        super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 600))

        self.wantsLayer = true
        self.layer!.backgroundColor = NSColor(white: 247/255, alpha: 1).cgColor

        self.dividerStyle = .thin

        let mainRegion = NSStackView()
        mainRegion.translatesAutoresizingMaskIntoConstraints = false
        mainRegion.orientation = .vertical

        // Create the header
        let header = NSTextField(labelWithString: "IR Debugger")
        header.font = NSFont.systemFont(ofSize: 33, weight: NSFontWeightSemibold)
        mainRegion.addFullWidthView(header)

        // Compile the program and set up the debugger
        do {
            let ast = try Parser.parse(sourceFile: sourceFile)
            try Typechecker.typecheck(node: ast)

            self.ir = IRGen.generateIR(forAST: ast)
            if let ir = ir {
                self.debugger = IRDebugger(ir: ir)
            }
        } catch {
            // Set up source view
            let sourceView = NSTextField()
            sourceView.backgroundColor = NSColor.white
            sourceView.drawsBackground = true
            sourceView.isBordered = false
            sourceView.attributedStringValue = sourceFile.highlightedString
            sourceView.translatesAutoresizingMaskIntoConstraints = false
            mainRegion.addFullWidthView(sourceView)

            let error = error as! CompilationError
            let errorView = NSTextField()
            errorView.translatesAutoresizingMaskIntoConstraints = false
            errorView.stringValue = "Compilation error:\n\(error)"
            errorView.isBordered = false
            errorView.isEditable = false

            mainRegion.addFullWidthView(errorView)

            addArrangedSubview(mainRegion)
            return
        }

        // Create the IR view
        irView.backgroundColor = NSColor.white
        irView.drawsBackground = true
        irView.isBordered = false
        irView.isEditable = false
        irView.translatesAutoresizingMaskIntoConstraints = false

        let irScrollView = NSScrollView()
        irScrollView.documentView = irView
        irScrollView.hasVerticalScroller = true
        irScrollView.translatesAutoresizingMaskIntoConstraints = false
        irScrollView.addConstraint(NSLayoutConstraint(item: irView, attribute: .width, relatedBy: .equal, toItem: irScrollView, attribute: .width, multiplier: 1, constant: 0))

        self.reset()

        mainRegion.addFullWidthView(irScrollView)

        addArrangedSubview(mainRegion)

        let footerStackView = NSStackView()
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        footerStackView.orientation = .vertical

        func createDebuggerButton(withTitle title: String, action: Selector) -> NSButton {
            let button = NSButton(title: title, target: self, action: action)
            button.font = NSFont.systemFont(ofSize: 20)
            button.isBordered = false
            button.translatesAutoresizingMaskIntoConstraints = false

            return button
        }

        // Create debugger buttons
        let stepButton = createDebuggerButton(withTitle: "⤼", action: #selector(self.step))
        stepButton.toolTip = "Step"
        let runUntilEndButton = createDebuggerButton(withTitle: "↠", action: #selector(self.runUntilEnd))
        runUntilEndButton.toolTip = "Run until end"
        let resetButton = createDebuggerButton(withTitle: "⟲", action: #selector(self.reset))
        resetButton.toolTip = "Reset"

        let debuggerButtonsView = NSStackView()
        debuggerButtonsView.addView(stepButton, in: .leading)
        debuggerButtonsView.addView(runUntilEndButton, in: .leading)
        debuggerButtonsView.addView(resetButton, in: .leading)
        footerStackView.addFullWidthView(debuggerButtonsView)


        // Create the stack frames view
        stackFramesDataSource.selectionDidChangeCallback = { [weak self] (selectedStackFrame: Int) in
            self?.didSelectStackFrame(stackFrame: selectedStackFrame)
        }

        stackFramesView.dataSource = self.stackFramesDataSource
        stackFramesView.delegate = self.stackFramesDataSource
        let stackFrameColumn = NSTableColumn(identifier: "StackFrame")
        stackFrameColumn.title = "Call stack"
        stackFrameColumn.tableView = stackFramesView
        stackFramesView.addTableColumn(stackFrameColumn)

        let stackFramesScrollView = NSScrollView()
        stackFramesScrollView.documentView = stackFramesView
        stackFramesScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackFramesScrollView.hasVerticalScroller = true

        // Create the registers view
        registerValuesView.dataSource = self.registerValuesViewDataSource
        registerValuesView.delegate = self.registerValuesViewDataSource
        let column = NSTableColumn(identifier: "RegisterValue")
        column.title = "Register values"
        column.tableView = registerValuesView
        registerValuesView.addTableColumn(column)

        let registerScrollView = NSScrollView()
        registerScrollView.documentView = registerValuesView
        registerScrollView.translatesAutoresizingMaskIntoConstraints = false
        registerScrollView.hasVerticalScroller = true

        // Create the results view
        resultsView.backgroundColor = NSColor.white
        resultsView.drawsBackground = true
        resultsView.isBordered = false
        resultsView.isEditable = false
        resultsView.translatesAutoresizingMaskIntoConstraints = false

        let resultsScrollView = NSScrollView()
        resultsScrollView.documentView = resultsView
        resultsScrollView.translatesAutoresizingMaskIntoConstraints = false
        resultsScrollView.hasVerticalScroller = true

        resultsScrollView.addConstraint(NSLayoutConstraint(item: resultsView, attribute: .width, relatedBy: .equal, toItem: resultsScrollView, attribute: .width, multiplier: 1, constant: 0))

        // Aggregate results and register view to footer

        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.addArrangedSubview(stackFramesScrollView)
        footerView.addArrangedSubview(registerScrollView)
        footerView.addArrangedSubview(resultsScrollView)
        footerView.isVertical = true
        footerView.dividerStyle = .thin

        footerStackView.addFullWidthView(footerView)

        addArrangedSubview(footerStackView)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidMoveToWindow() {
        self.window?.makeFirstResponder(self)

        self.setPosition(self.frame.size.height - 150, ofDividerAt: 0)
        footerView.setPosition(footerView.frame.size.width / 3, ofDividerAt: 0)
        footerView.setPosition(2 * footerView.frame.size.width / 3, ofDividerAt: 1)
    }

    @available(OSX 10.12.2, *)
    override public func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.stepItem, .continueItem, .resetItem]
        return touchBar
    }

    @available(OSX 10.12.2, *)
    public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItemIdentifier.stepItem:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "⤼", target: self, action: #selector(step))
            button.font = NSFont.systemFont(ofSize: 20)
            customViewItem.view = button
            return customViewItem
        case NSTouchBarItemIdentifier.continueItem:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "↠", target: self, action: #selector(runUntilEnd))
            button.font = NSFont.systemFont(ofSize: 20)
            customViewItem.view = button
            return customViewItem
        case NSTouchBarItemIdentifier.resetItem:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "⟲", target: self, action: #selector(reset))
            button.font = NSFont.systemFont(ofSize: 20)
            customViewItem.view = button
            return customViewItem
        default:
            return nil
        }
    }

    @objc func runUntilEnd() {
        guard let debugger = debugger else {
            return
        }

        var lastDebuggerState = debugger.debuggerState

        while debugger.debuggerState != nil {
            lastDebuggerState = debugger.debuggerState
            debugger.executeNextStep()
        }
        if let debuggerState = lastDebuggerState {
            populateViewsFromDebuggerState(debuggerState)
        }
    }

    @objc func step() {
        guard let debugger = debugger else {
            return
        }
        debugger.executeNextStep()

        if let debuggerState = debugger.debuggerState {
            populateViewsFromDebuggerState(debuggerState)
        }
    }

    private func populateViewsFromStackFrame(_ stackFrame: StackFrame) {
        setIRViewText(currentFunctionName: stackFrame.functionName,
                      currentBlock: stackFrame.block,
                      currentInstructionIndex: stackFrame.instructionIndex)

        self.registerValuesViewDataSource.registerValues = stackFrame.registers
        self.registerValuesView.reloadData()
    }

    private func didSelectStackFrame(stackFrame: Int) {
        populateViewsFromStackFrame(self.callStack[stackFrame])
    }

    @objc func reset() {
        guard let ir = ir else {
            return
        }

        debugger = IRDebugger(ir: ir)

        setIRViewText(currentFunctionName: "main",
                      currentBlock: ir.functions["main"]!.startBlock,
                      currentInstructionIndex: 0)

        self.registerValuesViewDataSource.registerValues = [:]
        self.registerValuesView.reloadData()

        self.resultsView.attributedStringValue = NSAttributedString(string: "")

        self.callStack = debugger!.debuggerState!.callStack

        populateViewsFromDebuggerState(debugger!.debuggerState!)
    }

    private func populateViewsFromDebuggerState(_ debuggerState: DebuggerState) {
        self.stackFramesDataSource.stackFrames = debuggerState.callStack
        self.callStack = debuggerState.callStack
        self.stackFramesView.reloadData()
        self.stackFramesView.selectRowIndexes([0], byExtendingSelection: false)

        let resultsString = NSAttributedString(string: debuggerState.output, attributes: [
            NSFontAttributeName: NSFont(name: "Menlo Bold", size: 11)!
            ])
        self.resultsView.attributedStringValue = resultsString
    }

    private func setIRViewText(currentFunctionName: String, currentBlock: BlockName, currentInstructionIndex: Int) {
        guard let ir = ir else {
            return
        }

        let result = NSMutableAttributedString()

        for (functionName, function) in ir.functions {
            result += (functionName + "(").monospacedString
            result += function.argumentRegisters.map({ $0.description }).joined(separator: ", ").monospacedString
            result += "): \n".monospacedString
            for blockName in function.blocks.keys.sorted(by: { $0.name < $1.name }) {
                let instructions = function.blocks[blockName]!
                result += "  \(blockName):\n".monospacedString
                for (index, instruction) in instructions.enumerated() {
                    let instructionString = NSMutableAttributedString(attributedString: ("    " + instruction.debugDescription + "\n").monospacedString)
                    if functionName == currentFunctionName && blockName == currentBlock && index == currentInstructionIndex {
                        instructionString.addAttribute(NSBackgroundColorAttributeName,
                                                       value: #colorLiteral(red: 0.8431372549, green: 0.9098039216, blue: 0.8549019608, alpha: 1),
                                                       range: NSRange(location: 0, length: instructionString.length))
                    }
                    result.append(instructionString)
                }
            }
            result += "\n".monospacedString
        }
        
        self.irView.attributedStringValue = result
    }
}
