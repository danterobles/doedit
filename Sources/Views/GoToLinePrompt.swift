import TUIkit

struct GoToLinePrompt: View {
    let isPresented: Binding<Bool>
    let state: EditorState

    var body: some View {
        Dialog(
            title: "Ir a línea",
            borderColor: .palette.border,
            titleColor: .palette.accent
        ) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 1) {
                    Text("Línea:")
                        .foregroundStyle(.palette.foregroundSecondary)
                    TextField(
                        "",
                        text: Binding(
                            get: { state.goToLineInput },
                            set: { state.goToLineInput = $0 }
                        ),
                        prompt: Text("número...")
                    )
                    .onSubmit { submitGoTo() }
                }
                rangeHintText
            }
        } footer: {
            HStack(spacing: 1) {
                Spacer()
                Button("Ir") { submitGoTo() }
                Button("Cancelar", role: .cancel) { isPresented.wrappedValue = false }
            }
        }
        .frame(width: 44)
        .onKeyPress { event in
            if event.key == .escape { isPresented.wrappedValue = false; return true }
            return false
        }
        .statusBarItems(.replace) {
            StatusBarItem(shortcut: Shortcut.escape, label: "cancelar")
            StatusBarItem(shortcut: Shortcut.enter, label: "ir")
        }
    }

    @ViewBuilder
    private var rangeHintText: some View {
        if let buffer = state.activeBuffer {
            Text("1 – \(buffer.lines.count) líneas")
                .foregroundStyle(.palette.foregroundTertiary)
        }
    }

    private func submitGoTo() {
        if let n = Int(state.goToLineInput.trimmingCharacters(in: .whitespaces)) {
            state.goToLine(n)
        }
        isPresented.wrappedValue = false
    }
}
