import Observation
import Foundation

@Observable
final class EditorState: @unchecked Sendable {
    var currentDirectory: String
    var files: [FileEntry] = []
    var selectedFileID: String? = nil
    var activeBuffer: TextBuffer? = nil
    var errorMessage: String? = nil

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
        } catch {
            errorMessage = "No se pudo abrir: \(error.localizedDescription)"
            activeBuffer = nil
        }
    }
}
