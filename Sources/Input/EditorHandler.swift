import TUIkit

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

        // Alt+letra — solo Alt+C (copiar); resto pasa al sistema
        if event.alt {
            guard case .character("c") = event.key else { return false }
            if let text = buffer.selectedText() {
                clipboard.content = text
                buffer.clearSelection()
            }
            return true
        }

        // Ctrl+letra — solo K (cortar) y U (pegar); resto pasa (Ctrl+S/Q/B → onKeyPress)
        if event.ctrl {
            switch event.key {
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
