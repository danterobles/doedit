import TUIkit

struct RootView: View {
    @Environment(\.statusBar) var statusBar
    @State private var state: EditorState
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    init(directory: String) {
        _state = State(wrappedValue: EditorState(directory: directory))
    }

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                SidebarView(state: state)
            },
            detail: {
                if let buffer = state.activeBuffer {
                    EditorView(buffer: buffer)
                } else {
                    VStack {
                        Text("doedit")
                            .bold()
                        Text(state.errorMessage ?? "Selecciona un archivo del panel lateral")
                            .foregroundStyle(.palette.foregroundSecondary)
                    }
                    .padding()
                }
            }
        )
        .onChange(of: state.selectedFileID) { _, path in
            if let path {
                state.openFile(path)
            }
        }
        .onKeyPress { event in
            if event.ctrl && event.key == .character("b") {
                columnVisibility = columnVisibility == .all ? .detailOnly : .all
                return true
            }
            return false
        }
        .onAppear {
            statusBar.quitShortcut = .ctrlQ
        }
        .statusBarItems(.replace) {
            if let buffer = state.activeBuffer, buffer.isDirty {
                StatusBarItem(shortcut: "*", label: "modificado")
            }
            StatusBarItem(shortcut: Shortcut.ctrl("b"), label: "sidebar")
            StatusBarItem(shortcut: Shortcut.ctrl("q"), label: "salir")
        }
    }
}
