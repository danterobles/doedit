import Foundation

public struct FileEntry: Identifiable, Hashable, Sendable {
    public let id: String       // ruta absoluta — clave de selección
    public let name: String     // nombre para mostrar
    public let isDirectory: Bool

    public init(id: String, name: String, isDirectory: Bool) {
        self.id = id
        self.name = name
        self.isDirectory = isDirectory
    }

    public var displayName: String {
        isDirectory ? name + "/" : name
    }
}
