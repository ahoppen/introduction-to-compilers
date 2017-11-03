import Cocoa

class SyntaxHighlighter {
    typealias Result = Void

    private static let numberColor: NSColor = #colorLiteral(red: 0.1098039216, green: 0, blue: 0.8117647059, alpha: 1)
    private static let stringColor: NSColor = #colorLiteral(red: 0.768627451, green: 0.1019607843, blue: 0.0862745098, alpha: 1)
    private static let keywordColor: NSColor = #colorLiteral(red: 0.6666666667, green: 0.05098039216, blue: 0.568627451, alpha: 1)
    private static let identifierColor: NSColor = #colorLiteral(red: 0.1490196078, green: 0.2784313725, blue: 0.2941176471, alpha: 1)

    /// Create a monospaced attributed string where characters have been coloured according to 
    /// Xcode's default syntax highlighting scheme
    ///
    /// - Parameter sourceFile: The source file to highlight
    /// - Returns: The syntax-highlighted source code
    static func highlight(sourceFile: SwiftFile) -> NSAttributedString {
        var workingString = NSMutableAttributedString(attributedString: sourceFile.sourceCode.monospacedString)
        let lexer = Lexer(sourceCode: sourceFile.sourceCode)
        do {
            var token = try lexer.nextToken()
            while token != .endOfFile {
                let color: NSColor?
                switch token.payload {
                case .if, .else, .func, .return:
                    color = keywordColor
                case .integer(_):
                    color = numberColor
                case .identifier(_):
                    color = identifierColor
                case .stringLiteral(_):
                    color = stringColor
                default:
                    color = nil
                }
                if let color = color {
                    self.color(range: token.sourceRange, in: &workingString, withColor: color)
                }

                token = try lexer.nextToken()
            }
        } catch {}

        return workingString
    }

    /// Colour part of a `NSMutableAttributedString` in a colour
    ///
    /// - Parameters:
    ///   - range: The source range to colour
    ///   - string: The string to colour
    ///   - color: The colour that the given range shall be assigned in the string
    private static func color(range: SourceRange,
                              in string: inout NSMutableAttributedString,
                              withColor color: NSColor) {
        let textRange = NSRange(location: range.start.offset,
                                length: range.end.offset - range.start.offset)

        string.addAttributes([.foregroundColor: color], range: textRange)
    }
}
