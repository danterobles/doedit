import TUIkit

struct EditorView: View {
    let buffer: TextBuffer
    let clipboard: Clipboard

    var body: some View {
        _EditorViewCore(buffer: buffer, clipboard: clipboard)
    }
}

private struct _EditorViewCore: View, Renderable {
    let buffer: TextBuffer
    let clipboard: Clipboard

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
                let emptyNum = String(repeating: " ", count: numWidth)
                outputLines.append("\u{1B}[2m\(emptyNum)\u{1B}[0m" + String(repeating: " ", count: contentWidth))
                continue
            }

            let numStr = String(format: "%\(numWidth - 1)d ", lineIdx + 1)
            let lineNum = "\u{1B}[2m\(numStr)\u{1B}[0m"

            let isCursorRow = lineIdx == buffer.cursor.line
            let screenCursorCol = isCursorRow ? buffer.cursor.column - buffer.horizontalOffset : nil
            let selCols = buffer.selectionColumns(forLine: lineIdx)

            let content = renderLine(
                buffer.lines[lineIdx],
                colOffset: buffer.horizontalOffset,
                width: contentWidth,
                cursorScreenCol: screenCursorCol,
                selectionCols: selCols
            )

            outputLines.append(lineNum + content)
        }

        return FrameBuffer(lines: outputLines)
    }

    private func renderLine(
        _ rawLine: String,
        colOffset: Int,
        width: Int,
        cursorScreenCol: Int?,
        selectionCols: Range<Int>?
    ) -> String {
        let chars = Array(rawLine)
        var result = ""

        for i in 0..<width {
            let charIdx = colOffset + i
            let ch: Character = charIdx < chars.count
                ? (chars[charIdx] == "\t" ? " " : chars[charIdx])
                : " "

            let isCursor = cursorScreenCol.map { $0 == i } ?? false
            let isSelected = selectionCols.map { $0.contains(charIdx) } ?? false

            if isCursor || isSelected {
                result += "\u{1B}[7m\(ch)\u{1B}[0m"
            } else {
                result += String(ch)
            }
        }

        return result
    }

    private func registerHandler(context: RenderContext) {
        guard let storage = context.environment.stateStorage else { return }
        let key = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let box = storage.storage(
            for: key,
            default: EditorHandler(
                focusID: "editor-\(context.identity.path)",
                buffer: buffer,
                clipboard: clipboard
            )
        )
        let handler = box.value
        handler.buffer = buffer
        handler.clipboard = clipboard
        context.environment.focusManager.register(handler)
    }
}
