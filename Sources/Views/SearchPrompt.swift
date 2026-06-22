import TUIkit
import doeditCore

struct SearchPrompt: View {
    let isPresented: Binding<Bool>
    let state: EditorState

    var body: some View {
        Dialog(
            title: "Buscar",
            borderColor: .palette.border,
            titleColor: .palette.accent
        ) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 1) {
                    Text("Buscar:")
                        .foregroundStyle(.palette.foregroundSecondary)
                    TextField(
                        "",
                        text: Binding(
                            get: { state.searchTerm },
                            set: { state.searchTerm = $0 }
                        ),
                        prompt: Text("término de búsqueda...")
                    )
                    .onSubmit { state.nextMatch() }
                }
                matchStatusText
            }
        } footer: {
            HStack(spacing: 1) {
                Button(state.searchCaseSensitive ? "[Aa] ON" : "[Aa] OFF") {
                    state.searchCaseSensitive.toggle()
                    state.runSearch()
                }
                Spacer()
                Button("Cerrar", role: .cancel) { isPresented.wrappedValue = false }
            }
        }
        .frame(width: 52)
        .onChange(of: state.searchTerm) { _, _ in state.runSearch() }
        .onKeyPress { event in
            if event.key == .escape { isPresented.wrappedValue = false; return true }
            return false
        }
        .statusBarItems(.replace) {
            StatusBarItem(shortcut: Shortcut.escape, label: "cerrar")
            StatusBarItem(shortcut: Shortcut.enter, label: "siguiente")
            StatusBarItem(shortcut: "[Aa]", label: "mayúsculas")
        }
    }

    @ViewBuilder
    private var matchStatusText: some View {
        if state.searchTerm.isEmpty {
            Text("Escribe para buscar")
                .foregroundStyle(.palette.foregroundTertiary)
        } else if state.searchMatches.isEmpty {
            Text("Sin coincidencias")
                .foregroundStyle(.palette.warning)
        } else {
            Text("\(state.currentMatchIndex + 1) de \(state.searchMatches.count) coincidencia\(state.searchMatches.count == 1 ? "" : "s")")
                .foregroundStyle(.palette.success)
        }
    }
}
