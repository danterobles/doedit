import TUIkit

// Vista pública — usa body para delegar en el core privado
struct EditorView: View {
    let buffer: TextBuffer

    var body: some View {
        _EditorViewCore(buffer: buffer)
    }
}

// Core privado con renderizado directo al buffer ANSI.
// Implementa Renderable para acceder a context.availableWidth/Height.
private struct _EditorViewCore: View, Renderable {
    let buffer: TextBuffer

    var body: Never { fatalError("_EditorViewCore renders via Renderable") }

    @MainActor
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let H = context.availableHeight
        let W = context.availableWidth
        guard H > 0, W > 0 else { return FrameBuffer() }

        let numWidth = String(max(1, buffer.lines.count)).count + 1
        let contentWidth = max(1, W - numWidth)

        if !context.isMeasuring {
            buffer.lastViewportHeight = H
            buffer.lastViewportWidth = contentWidth
            buffer.ensureCursorVisible(viewportHeight: H, viewportWidth: contentWidth)
            registerHandler(context: context)
        }

        var outputLines: [String] = []
        let startLine = buffer.scrollOffset

        for row in 0..<H {
            let lineIdx = startLine + row

            guard lineIdx < buffer.lines.count else {
                // Más allá del final del archivo
                let emptyNum = String(repeating: " ", count: numWidth)
                outputLines.append("\u{1B}[2m\(emptyNum)\u{1B}[0m" + String(repeating: " ", count: contentWidth))
                continue
            }

            // Número de línea (dim, alineado a la derecha)
            let numStr = String(format: "%\(numWidth - 1)d ", lineIdx + 1)
            let lineNum = "\u{1B}[2m\(numStr)\u{1B}[0m"

            // Contenido con cursor
            let isCursorRow = lineIdx == buffer.cursor.line
            let screenCol = isCursorRow ? buffer.cursor.column - buffer.horizontalOffset : nil
            let content = renderLine(buffer.lines[lineIdx], colOffset: buffer.horizontalOffset,
                                     width: contentWidth, cursorScreenCol: screenCol)

            outputLines.append(lineNum + content)
        }

        return FrameBuffer(lines: outputLines)
    }

    // Renderiza una línea del buffer con cursor invertido en la posición indicada.
    private func renderLine(_ rawLine: String, colOffset: Int, width: Int, cursorScreenCol: Int?) -> String {
        let chars = Array(rawLine)
        var result = ""

        for i in 0..<width {
            let charIdx = colOffset + i
            let ch: Character
            if charIdx < chars.count {
                let c = chars[charIdx]
                ch = c == "\t" ? " " : c  // tab → espacio para alineación consistente
            } else {
                ch = " "
            }

            if let col = cursorScreenCol, i == col {
                result += "\u{1B}[7m\(ch)\u{1B}[0m"  // invertido = cursor
            } else {
                result += String(ch)
            }
        }

        return result
    }

    // Recupera o crea el EditorHandler y lo registra con el FocusManager.
    private func registerHandler(context: RenderContext) {
        guard let storage = context.environment.stateStorage else { return }
        let key = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let box = storage.storage(
            for: key,
            default: EditorHandler(focusID: "editor-\(context.identity.path)", buffer: buffer)
        )
        let handler = box.value
        handler.buffer = buffer  // sincronizar si el archivo cambió
        context.environment.focusManager.register(handler)
    }
}
