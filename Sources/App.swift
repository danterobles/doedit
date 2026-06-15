import TUIkit
import Foundation

@main
struct doeditApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(directory: startDirectory())
        }
    }

    private func startDirectory() -> String {
        // Usa el primer argumento posicional, o el directorio actual
        let args = CommandLine.arguments.dropFirst()
        if let path = args.first {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                return path
            }
        }
        return FileManager.default.currentDirectoryPath
    }
}
