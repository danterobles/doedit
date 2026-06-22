import TUIkit
import doeditCore

final class EditorHandler: Focusable, @unchecked Sendable {
    let focusID: String
    var buffer: TextBuffer
    var clipboard: Clipboard

    init(focusID: String, buffer: TextBuffer, clipboard: Clipboard) {
        self.focusID = focusID
        self.buffer = buffer
        self.clipboard = clipboard
    }

    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        // Tab → navegación de foco entre paneles (FocusManager lo maneja)
        if event.key == .tab { return false }

        // En modo solo lectura bloquear mutaciones; permitir navegación y Alt+C (copiar)
        if buffer.isReadOnly {
            if event.alt, case .character("c") = event.key {
                // Alt+C (copiar selección) — permitido, continuar
            } else if !event.ctrl && !event.alt {
                switch event.key {
                case .left, .right, .up, .down, .home, .end, .pageUp, .pageDown:
                    break // navegación permitida
                default:
                    return false
                }
            } else {
                return false
            }
        }

        // Alt+letra — solo Alt+C (copiar); resto pasa al sistema
        if event.alt {
            guard case .character("c") = event.key else { return false }
            if let text = buffer.selectedText() {
                clipboard.content = text
                buffer.clearSelection()
            }
            return true
        }

        // Ctrl+letra — K (cortar), U (pegar), Z (deshacer), Y (rehacer)
        if event.ctrl {
            switch event.key {
            case .character("z"):
                buffer.undo()
                buffer.ensureCursorVisible(
                    viewportHeight: buffer.lastViewportHeight,
                    viewportWidth: buffer.lastViewportWidth
                )
                return true

            case .character("y"):
                buffer.redo()
                buffer.ensureCursorVisible(
                    viewportHeight: buffer.lastViewportHeight,
                    viewportWidth: buffer.lastViewportWidth
                )
                return true

            case .character("k"):
                if buffer.selection != nil {
                    clipboard.content = buffer.selectedText() ?? ""
                    buffer.deleteSelection()
                } else {
                    clipboard.content = buffer.cutLine()
                }
                buffer.ensureCursorVisible(
                    viewportHeight: buffer.lastViewportHeight,
                    viewportWidth: buffer.lastViewportWidth
                )
                return true

            case .character("u"):
                guard !clipboard.content.isEmpty else { return true }
                if buffer.selection != nil { buffer.deleteSelection() }
                buffer.insert(text: clipboard.content)
                buffer.ensureCursorVisible(
                    viewportHeight: buffer.lastViewportHeight,
                    viewportWidth: buffer.lastViewportWidth
                )
                return true

            default:
                return false
            }
        }

        // Teclas ordinarias
        switch event.key {
        case .character(let ch):
            if buffer.selection != nil { buffer.deleteSelection() }
            buffer.insert(ch)

        case .enter:
            if buffer.selection != nil { buffer.deleteSelection() }
            buffer.insertNewline()

        case .backspace:
            if buffer.selection != nil {
                buffer.deleteSelection()
            } else {
                buffer.deleteBackward()
            }

        case .delete:
            if buffer.selection != nil {
                buffer.deleteSelection()
            } else {
                buffer.deleteForward()
            }

        // Movimiento con soporte de selección via Shift
        case .left:
            if event.shift { buffer.startSelectionIfNeeded() } else { buffer.clearSelection() }
            buffer.moveLeft()
            if event.shift { buffer.updateSelectionHead() }

        case .right:
            if event.shift { buffer.startSelectionIfNeeded() } else { buffer.clearSelection() }
            buffer.moveRight()
            if event.shift { buffer.updateSelectionHead() }

        case .up:
            if event.shift { buffer.startSelectionIfNeeded() } else { buffer.clearSelection() }
            buffer.moveUp()
            if event.shift { buffer.updateSelectionHead() }

        case .down:
            if event.shift { buffer.startSelectionIfNeeded() } else { buffer.clearSelection() }
            buffer.moveDown()
            if event.shift { buffer.updateSelectionHead() }

        case .home:
            if event.shift { buffer.startSelectionIfNeeded() } else { buffer.clearSelection() }
            buffer.moveLineStart()
            if event.shift { buffer.updateSelectionHead() }

        case .end:
            if event.shift { buffer.startSelectionIfNeeded() } else { buffer.clearSelection() }
            buffer.moveLineEnd()
            if event.shift { buffer.updateSelectionHead() }

        case .pageUp:
            buffer.clearSelection()
            buffer.pageUp(viewportHeight: buffer.lastViewportHeight)

        case .pageDown:
            buffer.clearSelection()
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
