import Testing
@testable import doeditCore

@Suite("Selection")
struct SelectionTests {

    @Test func normalizedForwardSelection() {
        let a = CursorPosition(line: 0, column: 0)
        let b = CursorPosition(line: 0, column: 5)
        let sel = Selection(anchor: a, head: b)
        let (start, end) = sel.normalized()
        #expect(start == a)
        #expect(end == b)
    }

    @Test func normalizedBackwardSelection() {
        let a = CursorPosition(line: 0, column: 5)
        let b = CursorPosition(line: 0, column: 0)
        let sel = Selection(anchor: a, head: b)
        let (start, end) = sel.normalized()
        #expect(start.column == 0)
        #expect(end.column == 5)
    }

    @Test func isEmpty() {
        let pos = CursorPosition(line: 0, column: 3)
        let sel = Selection(anchor: pos, head: pos)
        #expect(sel.isEmpty)
    }

    @Test func isNotEmpty() {
        let sel = Selection(
            anchor: CursorPosition(line: 0, column: 0),
            head: CursorPosition(line: 0, column: 1)
        )
        #expect(!sel.isEmpty)
    }

    @Test func containsInsideSelection() {
        let sel = Selection(
            anchor: CursorPosition(line: 1, column: 2),
            head: CursorPosition(line: 1, column: 8)
        )
        #expect(sel.contains(line: 1, column: 5))
    }

    @Test func doesNotContainEndBoundary() {
        let sel = Selection(
            anchor: CursorPosition(line: 0, column: 0),
            head: CursorPosition(line: 0, column: 5)
        )
        #expect(!sel.contains(line: 0, column: 5))
    }

    @Test func doesNotContainOutside() {
        let sel = Selection(
            anchor: CursorPosition(line: 0, column: 2),
            head: CursorPosition(line: 0, column: 6)
        )
        #expect(!sel.contains(line: 0, column: 0))
        #expect(!sel.contains(line: 0, column: 9))
    }

    @Test func selectedTextSingleLine() {
        let buf = TextBuffer(lines: ["hello world"])
        buf.selection = Selection(
            anchor: CursorPosition(line: 0, column: 6),
            head: CursorPosition(line: 0, column: 11)
        )
        #expect(buf.selectedText() == "world")
    }

    @Test func selectedTextMultiLine() {
        let buf = TextBuffer(lines: ["hello", "world"])
        buf.selection = Selection(
            anchor: CursorPosition(line: 0, column: 3),
            head: CursorPosition(line: 1, column: 3)
        )
        #expect(buf.selectedText() == "lo\nwor")
    }

    @Test func deleteSelectionSingleLine() {
        let buf = TextBuffer(lines: ["hello world"])
        buf.selection = Selection(
            anchor: CursorPosition(line: 0, column: 5),
            head: CursorPosition(line: 0, column: 11)
        )
        buf.deleteSelection()
        #expect(buf.lines[0] == "hello")
        #expect(buf.selection == nil)
        #expect(buf.cursor.column == 5)
    }

    @Test func deleteSelectionMultiLine() {
        let buf = TextBuffer(lines: ["abc", "def", "ghi"])
        buf.selection = Selection(
            anchor: CursorPosition(line: 0, column: 1),
            head: CursorPosition(line: 2, column: 2)
        )
        buf.deleteSelection()
        #expect(buf.lines.count == 1)
        #expect(buf.lines[0] == "ai")
    }

    @Test func selectionColumnsForLine() {
        let buf = TextBuffer(lines: ["hello world"])
        buf.selection = Selection(
            anchor: CursorPosition(line: 0, column: 2),
            head: CursorPosition(line: 0, column: 7)
        )
        let range = buf.selectionColumns(forLine: 0)
        #expect(range == 2..<7)
    }
}
