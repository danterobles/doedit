import Foundation

struct FileEntry: Identifiable, Hashable, Sendable {
    let id: String       // ruta absoluta — clave de selección
    let name: String     // nombre para mostrar
    let isDirectory: Bool

    var displayName: String {
        isDirectory ? name + "/" : name
    }
}
