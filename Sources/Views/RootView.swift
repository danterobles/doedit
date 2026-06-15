import TUIkit
import Darwin

struct RootView: View {
    @Environment(\.statusBar) var statusBar
    @State private var state: EditorState
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showQuitAlert = false
    @State private var writeError: String? = nil

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
                    EditorView(buffer: buffer, clipboard: state.clipboard)
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
            if event.ctrl {
                switch event.key {
                case .character("s"):
                    do {
                        try state.saveCurrentBuffer()
                        NotificationService.current.post("Guardado")
                    } catch {
                        writeError = error.localizedDescription
                    }
                    return true
                case .character("q"):
                    if state.activeBuffer?.isDirty == true {
                        showQuitAlert = true
                        return true
                    }
                    return false
                case .character("b"):
                    columnVisibility = columnVisibility == .all ? .detailOnly : .all
                    return true
                case .character("w"):
                    if state.activeBuffer != nil {
                        state.showSearch = true
                    }
                    return true
                case .character("r"):
                    if state.activeBuffer != nil {
                        state.showReplace = true
                    }
                    return true
                case .character("g"):
                    if state.activeBuffer != nil {
                        state.goToLineInput = ""
                        state.showGoToLine = true
                    }
                    return true
                default:
                    return false
                }
            }
            if event.alt {
                switch event.key {
                case .character("w"):
                    state.nextMatch()
                    return true
                case .character("W"):   // Alt+Shift+W
                    state.prevMatch()
                    return true
                default:
                    return false
                }
            }
            return false
        }
        .onAppear {
            statusBar.quitShortcut = .ctrlQ
        }
        .statusBarItems(.replace) {
            if let buffer = state.activeBuffer {
                if buffer.isDirty {
                    StatusBarItem(shortcut: "*", label: "modificado")
                }
                if buffer.selection != nil {
                    StatusBarItem(shortcut: "SEL", label: "selección")
                }
                StatusBarItem(shortcut: Shortcut.ctrl("s"), label: "guardar")
                StatusBarItem(shortcut: Shortcut.ctrl("w"), label: "buscar")
                StatusBarItem(shortcut: Shortcut.ctrl("r"), label: "reemplazar")
                StatusBarItem(shortcut: Shortcut.ctrl("g"), label: "ir a línea")
                StatusBarItem(shortcut: "⌥c", label: "copiar")
                StatusBarItem(shortcut: Shortcut.ctrl("k"), label: "cortar")
                StatusBarItem(shortcut: Shortcut.ctrl("u"), label: "pegar")
            }
            StatusBarItem(shortcut: Shortcut.ctrl("b"), label: "sidebar")
            StatusBarItem(shortcut: Shortcut.ctrl("q"), label: "salir")
        }
        .modal(isPresented: Binding(
            get: { state.showSearch },
            set: { state.showSearch = $0 }
        )) {
            SearchPrompt(
                isPresented: Binding(get: { state.showSearch }, set: { state.showSearch = $0 }),
                state: state
            )
        }
        .modal(isPresented: Binding(
            get: { state.showGoToLine },
            set: { state.showGoToLine = $0 }
        )) {
            GoToLinePrompt(
                isPresented: Binding(get: { state.showGoToLine }, set: { state.showGoToLine = $0 }),
                state: state
            )
        }
        .modal(isPresented: Binding(
            get: { state.showReplace },
            set: { state.showReplace = $0 }
        )) {
            ReplacePrompt(
                isPresented: Binding(get: { state.showReplace }, set: { state.showReplace = $0 }),
                state: state
            )
        }
        .alert("¿Guardar cambios?", isPresented: $showQuitAlert) {
            Button("Guardar y salir") {
                do {
                    try state.saveCurrentBuffer()
                    showQuitAlert = false
                    raise(SIGINT)
                } catch {
                    showQuitAlert = false
                    writeError = error.localizedDescription
                }
            }
            Button("Descartar") {
                showQuitAlert = false
                raise(SIGINT)
            }
            Button("Cancelar", role: .cancel) {
                showQuitAlert = false
            }
        } message: {
            Text("El archivo tiene cambios sin guardar.")
        }
        .alert("Error al guardar", isPresented: Binding(
            get: { writeError != nil },
            set: { if !$0 { writeError = nil } }
        )) {
            Button("Aceptar", role: .cancel) { writeError = nil }
        } message: {
            Text(writeError ?? "")
        }
        .notificationHost()
    }
}
