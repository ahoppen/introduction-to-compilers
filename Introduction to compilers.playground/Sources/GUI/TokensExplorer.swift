import Cocoa

/// Shows the syntax-highlighted source code of a `SwiftFile` and shows tooltips
/// with the token's description when hovering over the source code
open class TokensExplorer: NSSplitView {

    private let sourceFile: SwiftFile
    public let sourceViewer: TokenHoverView
    private let sourceViewerScrollView = NSScrollView()
    private let mainArea = NSStackView()

    public init(forSourceFile sourceFile: SwiftFile, withParser parser: Parser = Parser()) {
        self.sourceFile = sourceFile

        self.sourceViewer = TokenHoverView(frame: CGRect(x: 0, y: 0, width: 50, height: 600),
                                           sourceFile: sourceFile)
        self.sourceViewer.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 600))

        self.wantsLayer = true
        self.layer!.backgroundColor = NSColor(white: 247/255, alpha: 1).cgColor

        // Create header
        let sourceCodeHeader = NSTextField(labelWithString: "Source Code")
        sourceCodeHeader.font = NSFont.systemFont(ofSize: 33, weight: NSFont.Weight.semibold)

        sourceViewerScrollView.documentView = self.sourceViewer
        sourceViewerScrollView.translatesAutoresizingMaskIntoConstraints = false
        sourceViewerScrollView.hasVerticalScroller = true
        sourceViewerScrollView.addConstraint(NSLayoutConstraint(item: sourceViewer, attribute: .width, relatedBy: .equal, toItem: sourceViewerScrollView, attribute: .width, multiplier: 1, constant: 0))

        mainArea.orientation = .vertical
        mainArea.translatesAutoresizingMaskIntoConstraints = false
        mainArea.addFullWidthView(sourceCodeHeader)
        mainArea.addFullWidthView(sourceViewerScrollView)

        self.addArrangedSubview(mainArea)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        let trackingArea = NSTrackingArea(rect: self.mainArea.frame, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited], owner: self.sourceViewer, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
} 
