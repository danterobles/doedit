import Testing
@testable import doeditCore

@Suite("Search and Replace")
struct SearchReplaceTests {

    @Test func searchFindsMatches() {
        let buf = TextBuffer(lines: ["foo bar foo"])
        let matches = buf.search(for: "foo", caseSensitive: true)
        #expect(matches.count == 2)
        #expect(matches[0].startColumn == 0)
        #expect(matches[0].endColumn == 3)
        #expect(matches[1].startColumn == 8)
        #expect(matches[1].endColumn == 11)
    }

    @Test func searchCaseInsensitive() {
        let buf = TextBuffer(lines: ["Foo foo FOO"])
        let matches = buf.search(for: "foo", caseSensitive: false)
        #expect(matches.count == 3)
    }

    @Test func searchCaseSensitiveMisses() {
        let buf = TextBuffer(lines: ["Foo FOO"])
        let matches = buf.search(for: "foo", caseSensitive: true)
        #expect(matches.isEmpty)
    }

    @Test func searchNoResults() {
        let buf = TextBuffer(lines: ["hello"])
        let matches = buf.search(for: "xyz", caseSensitive: true)
        #expect(matches.isEmpty)
    }

    @Test func searchEmptyTermReturnsEmpty() {
        let buf = TextBuffer(lines: ["hello"])
        let matches = buf.search(for: "", caseSensitive: true)
        #expect(matches.isEmpty)
    }

    @Test func searchAcrossLines() {
        let buf = TextBuffer(lines: ["abc", "def", "abc"])
        let matches = buf.search(for: "abc", caseSensitive: true)
        #expect(matches.count == 2)
        #expect(matches[0].line == 0)
        #expect(matches[1].line == 2)
    }

    @Test func replaceInLine() {
        let buf = TextBuffer(lines: ["hello world"])
        buf.replaceInLine(line: 0, startColumn: 6, endColumn: 11, with: "swift")
        #expect(buf.lines[0] == "hello swift")
    }

    @Test func replaceInLineOutOfBoundsLineIsNoop() {
        let buf = TextBuffer(lines: ["hello"])
        buf.replaceInLine(line: 5, startColumn: 0, endColumn: 3, with: "x")
        #expect(buf.lines.count == 1)
        #expect(buf.lines[0] == "hello")
    }

    @Test func replaceAllMatchesViaSingleLine() {
        let buf = TextBuffer(lines: ["aaa bbb aaa"])
        let state = EditorState(directory: "/tmp")
        state.activeBuffer = buf
        state.searchTerm = "aaa"
        state.replaceTerm = "xxx"
        state.runSearch()
        let count = state.replaceAllMatches()
        #expect(count == 2)
        #expect(buf.lines[0] == "xxx bbb xxx")
    }

    @Test func replaceAllMatchesAcrossLines() {
        let buf = TextBuffer(lines: ["cat", "dog", "cat"])
        let state = EditorState(directory: "/tmp")
        state.activeBuffer = buf
        state.searchTerm = "cat"
        state.replaceTerm = "bat"
        state.runSearch()
        let count = state.replaceAllMatches()
        #expect(count == 2)
        #expect(buf.lines[0] == "bat")
        #expect(buf.lines[1] == "dog")
        #expect(buf.lines[2] == "bat")
    }

    @Test func replaceCurrentMatch() {
        let buf = TextBuffer(lines: ["hello hello"])
        let state = EditorState(directory: "/tmp")
        state.activeBuffer = buf
        state.searchTerm = "hello"
        state.replaceTerm = "world"
        state.runSearch()
        state.replaceCurrentMatch()
        #expect(buf.lines[0] == "world hello")
    }
}
