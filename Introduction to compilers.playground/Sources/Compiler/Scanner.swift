/// The scanner reads the source code character by character and maintains the character's position
class Scanner {

    /// The source code as a list of `UnicodeScalar`s that can be picked one by one
    private let sourceCode: [UnicodeScalar]

    /// The index in `souceCode` that contains the character currently being scanned
    private var parsePosition = 0

    /// The location of the current character in the source code
    private(set) var sourceLoc = SourceLoc(line: 1, column: 1, offset: 0)

    init(sourceCode: String) {
        self.sourceCode = Array(sourceCode.unicodeScalars)
        self.parsePosition = self.sourceCode.startIndex
    }

    /// Peek at the current character without consuming it. Is `nil` if the end of the file has been
    /// reached
    var currentChar: UnicodeScalar? {
        guard parsePosition < sourceCode.count else {
            return nil
        }
        return sourceCode[parsePosition]
    }

    /// Consume the current character and move scanning one character ahead
    func consumeChar() {
        if currentChar == "\n" {
            self.sourceLoc.line += 1
            self.sourceLoc.column = 1
        } else {
            self.sourceLoc.column += 1
        }
        self.sourceLoc.offset += 1

        parsePosition += 1
    }
}
