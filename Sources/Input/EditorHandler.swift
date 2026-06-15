import TUIkit

// Manejador de teclado del editor. Implementa Focusable para recibir eventos
// cuando la vista del editor tiene el foco.
final class EditorHandler: Focusable, @unchecked Sendable {
    let focusID: String
    var buffer: TextBuffer

    init(focusID: String, buffer: TextBuffer) {
        self.focusID = focusID
        self.buffer = buffer
    }

    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        // Pasar combinaciones Ctrl+letra al sistema (Ctrl+Q salir, Ctrl+B sidebar, etc.)
        if event.ctrl { return false }
        // Pasar Alt (reservado para Phase 4-5: copiar, buscar)
        if event.alt { return false }
        // Pasar Tab para navegación de foco entre sidebar y editor
        if event.key == .tab { return false }

        switch event.key {
        case .character(let ch):
            buffer.insert(ch)
        case .enter:
            buffer.insertNewline()
        case .backspace:
            buffer.deleteBackward()
        case .delete:
            buffer.deleteForward()
        case .left:
            buffer.moveLeft()
        case .right:
            buffer.moveRight()
        case .up:
            buffer.moveUp()
        case .down:
            buffer.moveDown()
        case .home:
            buffer.moveLineStart()
        case .end:
            buffer.moveLineEnd()
        case .pageUp:
            buffer.pageUp(viewportHeight: buffer.lastViewportHeight)
        case .pageDown:
            buffer.pageDown(viewportHeight: buffer.lastViewportHeight)
        default:
            return false
        }

        buffer.ensureCursorVisible(
            viewportHeight: buffer.lastViewportHeight,
            viewportWidth: buffer.lastViewportWidth
        )
        return true
    }
}
