import TUIkit
import doeditCore

struct SidebarView: View {
    let state: EditorState

    var body: some View {
        List(selection: Binding(
            get: { state.selectedFileID },
            set: { state.selectedFileID = $0 }
        )) {
            ForEach(state.files) { file in
                Text(file.displayName)
            }
        }
        .statusBarItems {
            StatusBarItem(shortcut: "↑↓", label: "navegar")
            StatusBarItem(shortcut: "↵", label: "abrir")
        }
    }
}
