import Foundation

enum FileService {
    static let configExtensions: Set<String> = [
        "conf", "cfg", "ini", "yaml", "yml", "toml", "env", "json",
        "properties", "plist", "xml", "sh", "bash", "zsh", "fish"
    ]

    /// Lista el contenido de un directorio. Si showAll es false, filtra por extensiones de config.
    static func list(directory: String, showAll: Bool = true) -> [FileEntry] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: directory) else { return [] }

        return names
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .compactMap { name -> FileEntry? in
                guard !name.hasPrefix(".") else { return nil }  // ocultar dotfiles
                let path = (directory as NSString).appendingPathComponent(name)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return nil }
                if !isDir.boolValue && !showAll {
                    let ext = (name as NSString).pathExtension.lowercased()
                    guard configExtensions.contains(ext) else { return nil }
                }
                return FileEntry(id: path, name: name, isDirectory: isDir.boolValue)
            }
    }
}
