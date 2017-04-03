import Cocoa

public class TokenHoverView: NSTextView {
    private let tokenHoverView = NSTextField()

    // These variables need to be IUO since they would otherwise be overwritten
    // by init(frame:textcontainer) which is called out of line rdar://31317871
    private var tokens: [Token]! = nil
    private var sourceFile: SwiftFile! = nil

    init(frame: NSRect, sourceFile: SwiftFile) {
        super.init(frame: frame)

        self.sourceFile = sourceFile

        // Lex the source code for lexer tooltip 
        do {
            let lexer = Lexer(sourceCode: sourceFile.sourceCode)
            var tokens: [Token] = []
            var token: Token = try lexer.nextToken()
            while token.payload != TokenKind.endOfFile {
                tokens.append(token)
                token = try lexer.nextToken()
            }
            self.tokens = tokens
        } catch {
            self.tokens = []
        }

        // Set self layout
        self.backgroundColor = NSColor.white
        self.drawsBackground = true
        self.textStorage?.setAttributedString(self.sourceFile.highlightedString)
        self.isEditable = false
        self.textContainerInset = NSSize(width: -5, height: 0)

        // Create the hover view
        self.tokenHoverView.backgroundColor = NSColor(white: 0.95, alpha: 1)
        self.tokenHoverView.font = NSFont.systemFont(ofSize: 13)
        self.tokenHoverView.drawsBackground = true
        self.tokenHoverView.wantsLayer = true
        self.tokenHoverView.layer?.borderColor = NSColor.lightGray.cgColor
        self.tokenHoverView.layer?.borderWidth = 1
        self.tokenHoverView.isEditable = false
    }

    // Workaround for rdar://31317871
    public override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc override public func mouseMoved(with event: NSEvent) {
        // Determine the hover point in this frame
        let layoutManager = self.layoutManager!
        let textContainer = self.textContainer!
        let pointInTextView = self.convert(event.locationInWindow, from: nil)

        if pointInTextView.x < 0 || pointInTextView.x > self.frame.size.width ||
            pointInTextView.y < 0 || pointInTextView.y > self.frame.size.height {
            self.mouseExited(with: event)
            return
        }

        var pointInTextContainer = pointInTextView
        pointInTextContainer.x -= self.textContainerOrigin.x
        pointInTextContainer.y -= self.textContainerOrigin.y

        // Determine the hovered character
        let glyphIndex = layoutManager.glyphIndex(for: pointInTextContainer,
                                                  in: textContainer)

        // Get the token at that position
        let token = self.tokens.filter({ $0.sourceRange.start.offset <= glyphIndex && $0.sourceRange.end.offset > glyphIndex }).first

        // Display token
        if let token = token {
            tokenHoverView.stringValue = token.payload.description
            tokenHoverView.sizeToFit()
            let origin = CGPoint(x: pointInTextView.x,
                                 y: pointInTextView.y + 10)
            if self.tokenHoverView.superview == nil {
                self.window!.contentView!.addSubview(self.tokenHoverView)
            }
            tokenHoverView.frame.origin = self.convert(origin, to: self.window!.contentView!)
            tokenHoverView.frame.origin.y -= tokenHoverView.frame.size.height
        } else { 
            self.tokenHoverView.removeFromSuperview()
        }

        // Highlight the source range or remove the highlighting
        self.highlight(range: token?.sourceRange)
    }

    @objc public override func mouseExited(with event: NSEvent) {
        self.tokenHoverView.removeFromSuperview()
    }

    public func highlight(range: SourceRange?) {
        let highlightedString = NSMutableAttributedString(attributedString: sourceFile.highlightedString)
        if let range = range {
            highlightedString.addAttributes([
                NSBackgroundColorAttributeName: NSColor.selectedControlColor
                ], range: NSRange(location: range.start.offset, length: range.end.offset - range.start.offset))
        }
        textStorage?.setAttributedString(highlightedString)
    }
}
