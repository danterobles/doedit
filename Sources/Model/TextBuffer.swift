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

    var lastViewportHeight: Int = 24
    var lastViewportWidth: Int = 80

    var selection: Selection? = nil

    // MARK: - Undo/Redo

    private struct Snapshot: Sendable {
        let lines: [String]
        let cursor: CursorPosition
        let selection: Selection?
        let isDirty: Bool
    }

    @ObservationIgnored private var undoStack: [Snapshot] = []
    @ObservationIgnored private var redoStack: [Snapshot] = []
    @ObservationIgnored private var lastOpWasInsert = false
    @ObservationIgnored private var suppressSnapshots = false

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    private func saveSnapshot() {
        guard !suppressSnapshots else { return }
        if undoStack.count >= 50 { undoStack.removeFirst() }
        undoStack.append(Snapshot(lines: lines, cursor: cursor, selection: selection, isDirty: isDirty))
        redoStack.removeAll()
    }

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        redoStack.append(Snapshot(lines: lines, cursor: cursor, selection: selection, isDirty: isDirty))
        lines = snapshot.lines
        cursor = snapshot.cursor
        selection = snapshot.selection
        isDirty = snapshot.isDirty
        lastOpWasInsert = false
    }

    func redo() {
        guard let snapshot = redoStack.popLast() else { return }
        undoStack.append(Snapshot(lines: lines, cursor: cursor, selection: selection, isDirty: isDirty))
        lines = snapshot.lines
        cursor = snapshot.cursor
        selection = snapshot.selection
        isDirty = snapshot.isDirty
        lastOpWasInsert = false
    }

    // MARK: - Init

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
        if !lastOpWasInsert { saveSnapshot() }
        lastOpWasInsert = true
        var line = lines[cursor.line]
        let idx = index(in: line, at: cursor.column)
        line.insert(char, at: idx)
        lines[cursor.line] = line
        cursor.column += 1
        isDirty = true
    }

    func insertNewline() {
        saveSnapshot(); lastOpWasInsert = false
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
        saveSnapshot(); lastOpWasInsert = false
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
        saveSnapshot(); lastOpWasInsert = false
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

    // Pegar texto: una sola entrada en el historial para todo el bloque.
    func insert(text: String) {
        saveSnapshot(); lastOpWasInsert = false
        suppressSnapshots = true
        defer { suppressSnapshots = false; lastOpWasInsert = false }
        for ch in text {
            if ch == "\n" { insertNewline() } else { insert(ch) }
        }
    }

    // MARK: - Selección

    func startSelectionIfNeeded() {
        if selection == nil {
            selection = Selection(anchor: cursor, head: cursor)
        }
    }

    func updateSelectionHead() {
        selection?.head = cursor
        if selection?.isEmpty == true { selection = nil }
    }

    func clearSelection() { selection = nil }

    func selectedText() -> String? {
        guard let sel = selection, !sel.isEmpty else { return nil }
        let (start, end) = sel.normalized()

        if start.line == end.line {
            let chars = Array(lines[start.line])
            let s = min(start.column, chars.count)
            let e = min(end.column, chars.count)
            guard s < e else { return nil }
            return String(chars[s..<e])
        }

        var result = ""
        for li in start.line...end.line {
            let chars = Array(lines[li])
            if li == start.line {
                result += String(chars[min(start.column, chars.count)...]) + "\n"
            } else if li == end.line {
                result += String(chars[..<min(end.column, chars.count)])
            } else {
                result += lines[li] + "\n"
            }
        }
        return result.isEmpty ? nil : result
    }

    func deleteSelection() {
        guard let sel = selection, !sel.isEmpty else { return }
        saveSnapshot(); lastOpWasInsert = false
        let (start, end) = sel.normalized()

        if start.line == end.line {
            var chars = Array(lines[start.line])
            let s = min(start.column, chars.count)
            let e = min(end.column, chars.count)
            if s < e { chars.removeSubrange(s..<e) }
            lines[start.line] = String(chars)
        } else {
            let startChars = Array(lines[start.line])
            let endChars = Array(lines[end.line])
            let prefix = String(startChars[..<min(start.column, startChars.count)])
            let suffix = String(endChars[min(end.column, endChars.count)...])
            lines[start.line] = prefix + suffix
            lines.removeSubrange((start.line + 1)...end.line)
        }

        cursor = start
        selection = nil
        isDirty = true
    }

    func cutLine() -> String {
        saveSnapshot(); lastOpWasInsert = false
        let content = lines[cursor.line]
        if lines.count == 1 {
            lines[0] = ""
        } else {
            lines.remove(at: cursor.line)
            if cursor.line >= lines.count {
                cursor.line = max(0, lines.count - 1)
            }
        }
        cursor.column = 0
        isDirty = true
        return content + "\n"
    }

    func selectionColumns(forLine lineIdx: Int) -> Range<Int>? {
        guard let sel = selection, !sel.isEmpty else { return nil }
        let (start, end) = sel.normalized()
        guard lineIdx >= start.line && lineIdx <= end.line else { return nil }
        let lineLen = lines[lineIdx].count
        if start.line == end.line {
            return min(start.column, lineLen)..<min(end.column, lineLen)
        } else if lineIdx == start.line {
            return min(start.column, lineLen)..<lineLen
        } else if lineIdx == end.line {
            return 0..<min(end.column, lineLen)
        } else {
            return 0..<lineLen
        }
    }

    // MARK: - Reemplazo

    func replaceInLine(line: Int, startColumn: Int, endColumn: Int, with replacement: String) {
        guard line < lines.count else { return }
        saveSnapshot(); lastOpWasInsert = false
        let chars = Array(lines[line])
        let s = min(startColumn, chars.count)
        let e = min(endColumn, chars.count)
        lines[line] = String(chars[0..<s]) + replacement + String(chars[e...])
        isDirty = true
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
