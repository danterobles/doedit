import Foundation

// MARK: - CursorPosition ordering

extension CursorPosition: Comparable {
    public static func < (lhs: CursorPosition, rhs: CursorPosition) -> Bool {
        if lhs.line != rhs.line { return lhs.line < rhs.line }
        return lhs.column < rhs.column
    }
}

// MARK: - Selection

public struct Selection: Equatable, Sendable {
    public var anchor: CursorPosition
    public var head: CursorPosition

    public init(anchor: CursorPosition, head: CursorPosition) {
        self.anchor = anchor
        self.head = head
    }

    public var isEmpty: Bool { anchor == head }

    public func normalized() -> (start: CursorPosition, end: CursorPosition) {
        anchor <= head ? (anchor, head) : (head, anchor)
    }

    // Whether document position (line, col) falls inside the selection.
    // End column is exclusive (char at `end` is NOT selected).
    public func contains(line: Int, column: Int) -> Bool {
        let (start, end) = normalized()
        let pos = CursorPosition(line: line, column: column)
        return pos >= start && pos < end
    }
}

// MARK: - Clipboard

public final class Clipboard: @unchecked Sendable {
    public var content: String = ""

    public init() {}
}
