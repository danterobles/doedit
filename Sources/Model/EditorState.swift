import Observation
import Foundation

@Observable
final class EditorState: @unchecked Sendable {
    var currentDirectory: String
    var files: [FileEntry] = []
    var selectedFileID: String? = nil
    var activeBuffer: TextBuffer? = nil
    var errorMessage: String? = nil
    let clipboard = Clipboard()

    // MARK: - Búsqueda
    var showSearch = false
    var searchTerm: String = ""
    var searchCaseSensitive = false
    private(set) var searchMatches: [MatchPosition] = []
    private(set) var currentMatchIndex: Int = 0

    // MARK: - Ir a línea
    var showGoToLine = false
    var goToLineInput: String = ""

    init(directory: String) {
        self.currentDirectory = directory
        reload()
    }

    func reload() {
        files = FileService.list(directory: currentDirectory)
    }

    func openFile(_ path: String) {
        do {
            let (lines, ending) = try FileService.read(path: path)
            activeBuffer = TextBuffer(lines: lines, filePath: path, lineEnding: ending)
            errorMessage = nil
            // Limpia búsqueda activa al abrir nuevo archivo
            searchMatches = []
            currentMatchIndex = 0
        } catch {
            errorMessage = "No se pudo abrir: \(error.localizedDescription)"
            activeBuffer = nil
        }
    }

    func saveCurrentBuffer() throws {
        guard let buffer = activeBuffer, let path = buffer.filePath else { return }
        let content = buffer.serialize()
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        buffer.markClean()
    }

    // MARK: - Operaciones de búsqueda

    func runSearch() {
        guard let buffer = activeBuffer else { searchMatches = []; return }
        searchMatches = buffer.search(for: searchTerm, caseSensitive: searchCaseSensitive)
        currentMatchIndex = 0
        jumpToCurrentMatch()
    }

    func nextMatch() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % searchMatches.count
        jumpToCurrentMatch()
    }

    func prevMatch() {
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

    // MARK: - Ir a línea

    func goToLine(_ lineNumber: Int) {
        guard let buffer = activeBuffer else { return }
        let target = max(1, min(lineNumber, buffer.lines.count))
        buffer.moveTo(line: target - 1, column: 0)
        buffer.ensureCursorVisible(
            viewportHeight: buffer.lastViewportHeight,
            viewportWidth: buffer.lastViewportWidth
        )
    }
}
