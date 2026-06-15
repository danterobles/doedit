import Observation

enum LineEnding: Sendable {
    case lf    // \n
    case crlf  // \r\n (Windows)
}

struct CursorPosition: Equatable, Sendable {
    var line: Int    // 0-based
    var column: Int  // 0-based, en unidades de Character
}

@Observable
final class TextBuffer: @unchecked Sendable {
    private(set) var lines: [String]
    var cursor: CursorPosition
    var scrollOffset: Int
    var horizontalOffset: Int
    private(set) var isDirty: Bool
    var filePath: String?
    var lineEnding: LineEnding

    // Dimensiones del viewport — actualizadas por EditorView en cada render
    var lastViewportHeight: Int = 24
    var lastViewportWidth: Int = 80

    init(lines: [String] = [""], filePath: String? = nil, lineEnding: LineEnding = .lf) {
        self.lines = lines.isEmpty ? [""] : lines
        self.cursor = CursorPosition(line: 0, column: 0)
        self.scrollOffset = 0
        self.horizontalOffset = 0
        self.isDirty = false
        self.filePath = filePath
        self.lineEnding = lineEnding
    }

    // MARK: - Mutaciones

    func insert(_ char: Character) {
        guard char != "\r" else { return }
        var line = lines[cursor.line]
        let idx = index(in: line, at: cursor.column)
        line.insert(char, at: idx)
        lines[cursor.line] = line
        cursor.column += 1
        isDirty = true
    }

    func insertNewline() {
        let line = lines[cursor.line]
        let idx = index(in: line, at: cursor.column)
        let before = String(line[..<idx])
        let after = String(line[idx...])
        lines[cursor.line] = before
        lines.insert(after, at: cursor.line + 1)
        cursor.line += 1
        cursor.column = 0
        isDirty = true
    }

    func deleteBackward() {
        if cursor.column > 0 {
            var line = lines[cursor.line]
            let cur = index(in: line, at: cursor.column)
            let prev = line.index(before: cur)
            line.remove(at: prev)
            lines[cursor.line] = line
            cursor.column -= 1
        } else if cursor.line > 0 {
            let tail = lines.remove(at: cursor.line)
            cursor.line -= 1
            cursor.column = lines[cursor.line].count
            lines[cursor.line] += tail
        }
        isDirty = true
    }

    func deleteForward() {
        let line = lines[cursor.line]
        if cursor.column < line.count {
            var l = line
            l.remove(at: index(in: l, at: cursor.column))
            lines[cursor.line] = l
        } else if cursor.line < lines.count - 1 {
            let next = lines.remove(at: cursor.line + 1)
            lines[cursor.line] += next
        }
        isDirty = true
    }

    func insert(text: String) {
        for ch in text {
            if ch == "\n" { insertNewline() } else { insert(ch) }
        }
    }

    // MARK: - Movimiento

    func moveLeft() {
        if cursor.column > 0 {
            cursor.column -= 1
        } else if cursor.line > 0 {
            cursor.line -= 1
            cursor.column = lines[cursor.line].count
        }
    }

    func moveRight() {
        if cursor.column < lines[cursor.line].count {
            cursor.column += 1
        } else if cursor.line < lines.count - 1 {
            cursor.line += 1
            cursor.column = 0
        }
    }

    func moveUp() {
        if cursor.line > 0 {
            cursor.line -= 1
            cursor.column = min(cursor.column, lines[cursor.line].count)
        }
    }

    func moveDown() {
        if cursor.line < lines.count - 1 {
            cursor.line += 1
            cursor.column = min(cursor.column, lines[cursor.line].count)
        }
    }

    func moveLineStart() { cursor.column = 0 }

    func moveLineEnd() { cursor.column = lines[cursor.line].count }

    func moveTo(line: Int, column: Int) {
        cursor.line = max(0, min(line, lines.count - 1))
        cursor.column = max(0, min(column, lines[cursor.line].count))
    }

    func pageUp(viewportHeight: Int) {
        cursor.line = max(0, cursor.line - max(1, viewportHeight))
        cursor.column = min(cursor.column, lines[cursor.line].count)
    }

    func pageDown(viewportHeight: Int) {
        cursor.line = min(lines.count - 1, cursor.line + max(1, viewportHeight))
        cursor.column = min(cursor.column, lines[cursor.line].count)
    }

    // MARK: - Scroll

    func ensureCursorVisible(viewportHeight: Int, viewportWidth: Int) {
        guard viewportHeight > 0, viewportWidth > 0 else { return }
        if cursor.line < scrollOffset {
            scrollOffset = cursor.line
        } else if cursor.line >= scrollOffset + viewportHeight {
            scrollOffset = cursor.line - viewportHeight + 1
        }
        if cursor.column < horizontalOffset {
            horizontalOffset = cursor.column
        } else if cursor.column >= horizontalOffset + viewportWidth {
            horizontalOffset = cursor.column - viewportWidth + 1
        }
    }

    // MARK: - Serialización

    func serialize() -> String {
        let sep = lineEnding == .crlf ? "\r\n" : "\n"
        return lines.joined(separator: sep)
    }

    func markClean() { isDirty = false }

    // MARK: - Helpers

    private func index(in string: String, at column: Int) -> String.Index {
        let safe = min(max(0, column), string.count)
        return string.index(string.startIndex, offsetBy: safe)
    }
}
