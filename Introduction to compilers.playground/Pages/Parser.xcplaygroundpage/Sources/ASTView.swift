import Cocoa

fileprivate class TableViewCell: NSTableCellView {
    override var backgroundStyle: BackgroundStyle {
        didSet {
            switch backgroundStyle {
            case .light:
                self.textField?.textColor = NSColor.black
            case .dark:
                self.textField?.textColor = NSColor.white
            default:
                break
            }
        }
    }
}

fileprivate class ASTTreeViewItem {
    let node: ASTNode

    var children: [ASTTreeViewItem] {
        let childNodes: [ASTNode]
        if let casted = node as? IfStatement {
            childNodes = [casted.condition, casted.body, casted.elseBody].compactMap({ $0 })
        } else if let casted = node as? BraceStatement {
            childNodes = casted.body
        } else if let casted = node as? ReturnStatement {
            childNodes = [casted.expression]
        } else if let casted = node as? FunctionDeclaration {
            childNodes = casted.parameters + [casted.body]
        } else if let casted = node as? BinaryOperatorExpression {
            childNodes = [casted.lhs, casted.rhs]
        } else if let casted = node as? FunctionCallExpression {
            childNodes = casted.arguments.compactMap({ $0 })
        } else if let casted = node as? ASTRoot {
            childNodes = casted.statements
        } else {
            childNodes = []
        }
        return childNodes.map(ASTTreeViewItem.init)
    }

    public var label: NSAttributedString {
        let monospaceFontAttributes = [
            NSAttributedString.Key.font: NSFont(name: "Menlo", size: NSFont.systemFontSize)!
        ]
        if node is IfStatement {
            let str = NSMutableAttributedString(string: "If statement")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 0, length: 2))
            return str
        } else if node is BraceStatement {
            return NSAttributedString(string: "Brace statement")
        } else if node is ReturnStatement {
            return NSAttributedString(string: "Return statement")
        } else if let casted = node as? BinaryOperatorExpression {
            let str = NSMutableAttributedString(string: "Binary operator \(casted.operator.sourceCodeName)")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 16, length: str.length - 16))
            return str
        } else if let casted = node as? FunctionDeclaration {
            let str = NSMutableAttributedString(string: "Function \(casted.name)")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 9, length: str.length - 9))
            return str
        } else if let casted = node as? VariableDeclaration {
            let str = NSMutableAttributedString(string: "Variable \(casted.name)")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 9, length: str.length - 9))
            return str
        } else if let casted = node as? FunctionCallExpression {
            let str = NSMutableAttributedString(string: "Function call \(casted.functionName)")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 14, length: str.length - 14))
            return str
        } else if let casted = node as? IntegerLiteralExpression {
            let str = NSMutableAttributedString(string: "Integer literal \(casted.value)")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 16, length: str.length - 16))
            return str
        } else if let casted = node as? StringLiteralExpression {
            let str = NSMutableAttributedString(string: "String literal \(casted.value)")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 15, length: str.length - 15))
            return str
        } else if let casted = node as? IdentifierReferenceExpression {
            let str = NSMutableAttributedString(string: "Identifier reference \(casted.name)")
            str.setAttributes(monospaceFontAttributes, range: NSRange(location: 21, length: str.length - 21))
            return str
        } else {
            return NSAttributedString(string: "\(type(of: node))")
        }
    }

    init(node: ASTNode) {
        self.node = node
    }
}

fileprivate class ASTViewDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {

    let root: ASTTreeViewItem
    let selectionCallback: (ASTNode?) -> Void

    init(root: ASTRoot, selectionCallback: @escaping (ASTNode?) -> Void) {
        self.root = ASTTreeViewItem(node: root)
        self.selectionCallback = selectionCallback
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? ASTTreeViewItem {
            return item.children.count
        } else {
            return root.children.count
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? ASTTreeViewItem {
            return item.children[index]
        }

        return root.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return self.outlineView(outlineView, numberOfChildrenOfItem: item) > 0
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let item = item as! ASTTreeViewItem
        let textView = NSTextField(labelWithAttributedString: item.label)
        let cell = TableViewCell()
        cell.textField = textView
        cell.addSubview(textView)
        return cell
    }

    fileprivate func outlineViewSelectionDidChange(_ notification: Notification) {
        let outlineView = notification.object as! ASTView
        let selectedItem = outlineView.item(atRow: outlineView.selectedRow) as! ASTTreeViewItem?
        selectionCallback(selectedItem?.node)
    }
}

public class ASTView: NSOutlineView {

    private let astViewDataSource: ASTViewDataSource

    public init(frame: CGRect, astRoot: ASTRoot, selectionCallback: @escaping (ASTNode?) -> Void) {
        self.astViewDataSource = ASTViewDataSource(root: astRoot, selectionCallback: selectionCallback)

        super.init(frame: frame)

        self.dataSource = self.astViewDataSource
        self.delegate = self.astViewDataSource

        let column = NSTableColumn(identifier: .theColumn)
        column.tableView = self
        self.addTableColumn(column)
        self.outlineTableColumn = column

        self.headerView = nil

        self.expandItem(nil, expandChildren: true)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private extension NSUserInterfaceItemIdentifier {
    static let theColumn = NSUserInterfaceItemIdentifier("TheColumn")
}
