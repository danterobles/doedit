import Observation
import Foundation

@Observable
final class EditorState: @unchecked Sendable {
    var currentDirectory: String
    var files: [FileEntry] = []
    var selectedFileID: String? = nil

    init(directory: String) {
        self.currentDirectory = directory
        reload()
    }

    func reload() {
        files = FileService.list(directory: currentDirectory)
    }
}
