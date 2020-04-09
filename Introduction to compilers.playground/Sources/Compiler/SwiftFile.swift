import Foundation

/// Represents the source code that was contained in a `.swift` file
public struct SwiftFile: _ExpressibleByFileReferenceLiteral, CustomStringConvertible, CustomPlaygroundDisplayConvertible {
    public let sourceCode: String

    public init(fileReferenceLiteralResourceName path: String) {
        let url = Bundle.main.url(forResource: path, withExtension: nil)!
        sourceCode = try! String(contentsOf: url)
    }

    /// Create a `SwiftFile` with manually obtained source code
    ///
    /// - Parameter sourceCode: The source code of the file
    public init(fromSourceCode sourceCode: String) {
        self.sourceCode = sourceCode
    }

    public var description: String {
        return sourceCode
    }

    /// The syntax-highlighted source code of the file
    public var highlightedString: NSAttributedString {
        return SyntaxHighlighter.highlight(sourceFile: self)
    }

    public var playgroundDescription: Any {
        return self.highlightedString.withPlaygroundQuickLookBackgroundColor
    }
}
