import Testing
@testable import doeditCore

@Suite("TextBuffer")
struct TextBufferTests {

    @Test func insertCharacter() {
        let buf = TextBuffer()
        buf.insert("h"); buf.insert("i")
        #expect(buf.lines[0] == "hi")
        #expect(buf.cursor.column == 2)
    }

    @Test func insertNewline() {
        let buf = TextBuffer(lines: ["hello"])
        buf.cursor.column = 5
        buf.insertNewline()
        #expect(buf.lines == ["hello", ""])
        #expect(buf.cursor.line == 1)
        #expect(buf.cursor.column == 0)
    }

    @Test func insertNewlineAtMiddle() {
        let buf = TextBuffer(lines: ["hello"])
        buf.cursor.column = 2
        buf.insertNewline()
        #expect(buf.lines[0] == "he")
        #expect(buf.lines[1] == "llo")
    }

    @Test func deleteBackward() {
        let buf = TextBuffer(lines: ["hi"])
        buf.cursor.column = 2
        buf.deleteBackward()
        #expect(buf.lines[0] == "h")
        #expect(buf.cursor.column == 1)
    }

    @Test func deleteBackwardMergesLines() {
        let buf = TextBuffer(lines: ["hello", "world"])
        buf.cursor = CursorPosition(line: 1, column: 0)
        buf.deleteBackward()
        #expect(buf.lines.count == 1)
        #expect(buf.lines[0] == "helloworld")
        #expect(buf.cursor.line == 0)
        #expect(buf.cursor.column == 5)
    }

    @Test func deleteForward() {
        let buf = TextBuffer(lines: ["hi"])
        buf.cursor.column = 0
        buf.deleteForward()
        #expect(buf.lines[0] == "i")
    }

    @Test func deleteForwardMergesLines() {
        let buf = TextBuffer(lines: ["hello", "world"])
        buf.cursor = CursorPosition(line: 0, column: 5)
        buf.deleteForward()
        #expect(buf.lines.count == 1)
        #expect(buf.lines[0] == "helloworld")
    }

    @Test func undoSingleInsertBatch() {
        let buf = TextBuffer()
        buf.insert("a")
        buf.insert("b")
        buf.insert("c")
        #expect(buf.lines[0] == "abc")
        buf.undo()
        #expect(buf.lines[0] == "")
    }

    @Test func undoNewline() {
        let buf = TextBuffer(lines: ["hello"])
        buf.cursor.column = 5
        buf.insertNewline()
        buf.undo()
        #expect(buf.lines.count == 1)
        #expect(buf.lines[0] == "hello")
    }

    @Test func redo() {
        let buf = TextBuffer()
        buf.insert("a")
        buf.undo()
        buf.redo()
        #expect(buf.lines[0] == "a")
    }

    @Test func pasteInsertsAsOneUndoStep() {
        let buf = TextBuffer()
        buf.insert(text: "hello\nworld")
        #expect(buf.lines[0] == "hello")
        #expect(buf.lines[1] == "world")
        buf.undo()
        #expect(buf.lines == [""])
    }

    @Test func serialization() {
        let buf = TextBuffer(lines: ["a", "b", "c"])
        #expect(buf.serialize() == "a\nb\nc")
    }

    @Test func serializationCRLF() {
        let buf = TextBuffer(lines: ["a", "b"], lineEnding: .crlf)
        #expect(buf.serialize() == "a\r\nb")
    }

    @Test func markCleanClearsDirty() {
        let buf = TextBuffer()
        buf.insert("x")
        #expect(buf.isDirty)
        buf.markClean()
        #expect(!buf.isDirty)
    }

    @Test func cutLine() {
        let buf = TextBuffer(lines: ["foo", "bar"])
        buf.cursor = CursorPosition(line: 0, column: 0)
        let cut = buf.cutLine()
        #expect(cut == "foo\n")
        #expect(buf.lines == ["bar"])
    }

    @Test func moveLeftRight() {
        let buf = TextBuffer(lines: ["abc"])
        buf.moveRight()
        #expect(buf.cursor.column == 1)
        buf.moveLeft()
        #expect(buf.cursor.column == 0)
    }

    @Test func moveUpDown() {
        let buf = TextBuffer(lines: ["hello", "world"])
        buf.moveDown()
        #expect(buf.cursor.line == 1)
        buf.moveUp()
        #expect(buf.cursor.line == 0)
    }
}
