import Observation
import Foundation

@Observable
public final class EditorState: @unchecked Sendable {
    public var currentDirectory: String
    public var files: [FileEntry] = []
    public var selectedFileID: String? = nil
    public var activeBuffer: TextBuffer? = nil
    public var errorMessage: String? = nil
    public let clipboard = Clipboard()

    // MARK: - Búsqueda
    public var showSearch = false
    public var searchTerm: String = ""
    public var searchCaseSensitive = false
    public private(set) var searchMatches: [MatchPosition] = []
    public private(set) var currentMatchIndex: Int = 0

    // MARK: - Ir a línea
    public var showGoToLine = false
    public var goToLineInput: String = ""

    // MARK: - Buscar y reemplazar
    public var showReplace = false
    public var replaceTerm: String = ""

    public init(directory: String) {
        self.currentDirectory = directory
        reload()
    }

    public func reload() {
        files = FileService.list(directory: currentDirectory)
    }

    public func openFile(_ path: String) {
        do {
            let (lines, ending) = try FileService.read(path: path)
            let buffer = TextBuffer(lines: lines, filePath: path, lineEnding: ending)
            buffer.isReadOnly = !FileManager.default.isWritableFile(atPath: path)
            activeBuffer = buffer
            errorMessage = nil
            // Limpia búsqueda activa al abrir nuevo archivo
            searchMatches = []
            currentMatchIndex = 0
        } catch {
            errorMessage = error.localizedDescription
            activeBuffer = nil
        }
    }

    public func saveCurrentBuffer() throws {
        guard let buffer = activeBuffer, let path = buffer.filePath else { return }
        guard !buffer.isReadOnly else { return }
        let content = buffer.serialize()
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        buffer.markClean()
    }

    // MARK: - Operaciones de búsqueda

    public func runSearch() {
        guard let buffer = activeBuffer else { searchMatches = []; return }
        searchMatches = buffer.search(for: searchTerm, caseSensitive: searchCaseSensitive)
        currentMatchIndex = 0
        jumpToCurrentMatch()
    }

    public func nextMatch() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % searchMatches.count
        jumpToCurrentMatch()
    }

    public func prevMatch() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + searchMatches.count - 1) % searchMatches.count
        jumpToCurrentMatch()
    }

    private func jumpToCurrentMatch() {
        guard let buffer = activeBuffer, !searchMatches.isEmpty else { return }
        let match = searchMatches[currentMatchIndex]
        let start = CursorPosition(line: match.line, column: match.startColumn)
        let end = CursorPosition(line: match.line, column: match.endColumn)
        buffer.cursor = start
        buffer.selection = Selection(anchor: start, head: end)
        buffer.ensureCursorVisible(
            viewportHeight: buffer.lastViewportHeight,
            viewportWidth: buffer.lastViewportWidth
        )
    }

    // MARK: - Reemplazo

    public func replaceCurrentMatch() {
        guard !searchMatches.isEmpty, let buffer = activeBuffer else { return }
        let match = searchMatches[currentMatchIndex]
        buffer.replaceInLine(
            line: match.line,
            startColumn: match.startColumn,
            endColumn: match.endColumn,
            with: replaceTerm
        )
        runSearch()
    }

    @discardableResult
    public func replaceAllMatches() -> Int {
        guard !searchMatches.isEmpty, let buffer = activeBuffer else { return 0 }
        let sorted = searchMatches.sorted {
            $0.line != $1.line ? $0.line > $1.line : $0.startColumn > $1.startColumn
        }
        for match in sorted {
            buffer.replaceInLine(
                line: match.line,
                startColumn: match.startColumn,
                endColumn: match.endColumn,
                with: replaceTerm
            )
        }
        let count = sorted.count
        runSearch()
        return count
    }

    // MARK: - Ir a línea

    public func goToLine(_ lineNumber: Int) {
        guard let buffer = activeBuffer else { return }
        let target = max(1, min(lineNumber, buffer.lines.count))
        buffer.moveTo(line: target - 1, column: 0)
        buffer.ensureCursorVisible(
            viewportHeight: buffer.lastViewportHeight,
            viewportWidth: buffer.lastViewportWidth
        )
    }
}
