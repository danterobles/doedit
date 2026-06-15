import Foundation

// MARK: - CursorPosition ordering

extension CursorPosition: Comparable {
    public static func < (lhs: CursorPosition, rhs: CursorPosition) -> Bool {
        if lhs.line != rhs.line { return lhs.line < rhs.line }
        return lhs.column < rhs.column
    }
}

// MARK: - Selection

struct Selection: Equatable, Sendable {
    var anchor: CursorPosition
    var head: CursorPosition

    var isEmpty: Bool { anchor == head }

    func normalized() -> (start: CursorPosition, end: CursorPosition) {
        anchor <= head ? (anchor, head) : (head, anchor)
    }

    // Whether document position (line, col) falls inside the selection.
    // End column is exclusive (char at `end` is NOT selected).
    func contains(line: Int, column: Int) -> Bool {
        let (start, end) = normalized()
        let pos = CursorPosition(line: line, column: column)
        return pos >= start && pos < end
    }
}

// MARK: - Clipboard

final class Clipboard: @unchecked Sendable {
    var content: String = ""
}
