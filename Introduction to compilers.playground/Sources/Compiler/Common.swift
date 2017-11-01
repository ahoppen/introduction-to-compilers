import Cocoa

/// A location in the source code
public struct SourceLoc: CustomDebugStringConvertible {
    /// The line in the source code (starting at 1)
    public internal(set) var line: Int
    /// The column in the source code (starting at 1)
    public internal(set) var column: Int
    /// The toal offset of the location by just counting the characters in the source string 
    /// (starting at 0)
    public internal(set) var offset: Int

    public static let empty = SourceLoc(line: 0, column: 0, offset: 0)

    public var debugDescription: String {
        return "\(line):\(column)"
    }
}

/// A range in the source code
public struct SourceRange: CustomDebugStringConvertible {
    /// The start of the range (inclusive)
    public let start: SourceLoc
    /// The end of the range (exclusive)
    public let end: SourceLoc

    public static let empty = SourceRange(start: SourceLoc.empty, end: SourceLoc.empty)

    public var debugDescription: String {
        return "\(start.debugDescription)-\(end.debugDescription)"
    }
}

/// Error thrown when a compilation error occurs
public struct CompilationError: Error, CustomDebugStringConvertible, CustomPlaygroundQuickLookable {
    /// The location at which this error occurred
    public let location: SourceLoc
    /// The error message to be displayed to the user
    public let errorMessage: String

    public var debugDescription: String {
        return "\(location): \(errorMessage)"
    }

    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        return .text(debugDescription)
    }

    public init(sourceRange: SourceRange, errorMessage: String) {
        self.location = sourceRange.start
        self.errorMessage = errorMessage
    }

    public init(location: SourceLoc, errorMessage: String) {
        self.location = location
        self.errorMessage = errorMessage
    }
}

public extension String {
    public var monospacedString: NSAttributedString {
        let attrs = [
            NSAttributedStringKey.font: NSFont(name: "Menlo", size: 11)!
        ]
        return NSAttributedString(string: self, attributes: attrs)
    }
}

public extension NSAttributedString {
    public var withPlaygroundQuickLookBackgroundColor: NSAttributedString {
        let s = NSMutableAttributedString(attributedString: self)
        s.addAttribute(NSAttributedStringKey.backgroundColor, value: NSColor(white: 247.0/255, alpha: 1), range: NSRange(location: 0, length: s.length))
        return s
    }
}
