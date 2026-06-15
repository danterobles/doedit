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
            guard event.ctrl else { return false }
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
            default:
                return false
            }
        }
        .onAppear {
            statusBar.quitShortcut = .ctrlQ
        }
        .statusBarItems(.replace) {
            if let buffer = state.activeBuffer {
                if buffer.isDirty {
                    StatusBarItem(shortcut: "*", label: "modificado")
                }
                StatusBarItem(shortcut: Shortcut.ctrl("s"), label: "guardar")
            }
            StatusBarItem(shortcut: Shortcut.ctrl("b"), label: "sidebar")
            StatusBarItem(shortcut: Shortcut.ctrl("q"), label: "salir")
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
