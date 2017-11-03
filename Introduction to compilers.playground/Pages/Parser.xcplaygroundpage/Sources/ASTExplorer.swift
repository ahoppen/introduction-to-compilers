import Cocoa

/// View that let's the user explore the AST by showing a `TokensExplorer` on top
/// and an expendable AST below it
public class ASTExplorer: TokensExplorer {

    /// - Parameters:
    ///   - sourceFile: The source file for which the AST shall be explored
    ///   - parser: The parser used to parse the source code
    public override init(forSourceFile sourceFile: SwiftFile, withParser parser: Parser = Parser()) {
        super.init(forSourceFile: sourceFile, withParser: parser)

        // Parse the source code for the AST viewer
        var ast: ASTRoot?
        var compilationError: CompilationError? = nil
        do {
            ast = try parser.parse(sourceFile: sourceFile)
        } catch {
            compilationError = (error as! CompilationError)
            ast = nil
        }

        // Restrict the source viewer's height to 100
        let heightConstraint = NSLayoutConstraint(item: sourceViewer,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: 100)
        heightConstraint.priority = NSLayoutConstraint.Priority(rawValue: 900)
        sourceViewer.addConstraint(heightConstraint)

        // Create headers
        let astHeader = NSTextField(labelWithString: "AST")
        astHeader.font = .systemFont(ofSize: 33, weight: .semibold)

        // Create the ASTView
        let astView: NSView
        if let ast = ast {
            astView = ASTView(frame: self.frame, astRoot: ast, selectionCallback: self.highlightSourceCodeForNode)
        } else {
            astView = NSTextField(labelWithString: "Compilation error:\n\(compilationError!)")
        }

        // Put the ASTView into a scroll view
        let astScrollView = NSScrollView()
        astScrollView.documentView = astView
        astScrollView.hasVerticalScroller = true
        astScrollView.addConstraint(NSLayoutConstraint(item: astView, attribute: .width, relatedBy: .equal, toItem: astScrollView, attribute: .width, multiplier: 1, constant: 0))

        let footerView = NSStackView()
        footerView.orientation = .vertical
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.addFullWidthView(astHeader)
        footerView.addFullWidthView(astScrollView)

        addArrangedSubview(footerView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.setPosition(self.frame.size.height / 3, ofDividerAt: 0)
        self.updateTrackingAreas()
    }

    private func highlightSourceCodeForNode(node: ASTNode?) {
        self.sourceViewer.highlight(range: node?.sourceRange)
    }
}
