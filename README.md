# doedit

Editor TUI de archivos de configuración, estilo nano. Construido sobre [TUIkit](https://github.com/phranck/TUIkit).

## Compilar y ejecutar

```bash
swift build -c release
swift run                          # desarrollo
.build/release/doedit              # binario release
swift test                         # pruebas (cuando existan)
```

## Fase 0 — Discovery de TUIkit (hallazgos verificados)

> Fuente: código fuente resuelto por SPM en `.build/checkouts/TUIkit/`. No se asume el README.

### 1. Firma de `.onKeyPress()` y modificadores

Tres overloads en `Extensions/View+Events.swift`:

```swift
// Captura cualquier tecla; devolver true consume el evento
func onKeyPress(_ handler: @escaping (KeyEvent) -> Bool) -> some View

// Filtrar a un conjunto de teclas
func onKeyPress(keys: Set<Key>, handler: @escaping (KeyEvent) -> Bool) -> some View

// Tecla única; siempre consume (sin valor de retorno)
func onKeyPress(_ key: Key, action: @escaping () -> Void) -> some View
```

`KeyEvent` (en `TUIkitCore/Input/KeyEvent.swift`):

```swift
public struct KeyEvent: Equatable, Sendable {
    public let key: Key      // la tecla sin modificadores
    public let ctrl: Bool
    public let alt: Bool
    public let shift: Bool
}

public enum Key: Hashable, Sendable {
    case escape, enter, tab, backspace, delete, space
    case up, down, left, right
    case home, end, pageUp, pageDown
    case f1 ... f12
    case character(Character)
    case paste(String)
}
```

Ctrl+S llega como `KeyEvent(key: .character("s"), ctrl: true)`. Los modificadores son campos Bool separados, no parte de `Key`.

### 2. Ctrl+S y Ctrl+Q llegan a la app (IXON deshabilitado)

En `Rendering/Terminal.swift`, `enableRawMode()` deshabilita explícitamente IXON:

```swift
raw.c_iflag &= ~TermFlag(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
```

**Resultado verificado:** `Ctrl+S` (0x13) y `Ctrl+Q` (0x11) NO son interceptados por el terminal; llegan como `KeyEvent(key: .character("s"/"q"), ctrl: true)`. No se necesita workaround.

El shortcut de salida se configura con `statusBar.quitShortcut = .ctrlQ` via `@Environment(\.statusBar)`.

### 3. API real de `NavigationSplitView`

Dos y tres columnas, con o sin binding de visibilidad (`Views/NavigationSplitView.swift`):

```swift
// Dos columnas, control de visibilidad
NavigationSplitView(
    columnVisibility: $visibility,
    sidebar: { SidebarView() },
    detail: { EditorView() }
)

// Valores de NavigationSplitViewVisibility:
NavigationSplitViewVisibility.all          // muestra todas las columnas
NavigationSplitViewVisibility.detailOnly   // oculta sidebar
NavigationSplitViewVisibility.doubleColumn // oculta sidebar (2 columnas: content+detail)
NavigationSplitViewVisibility.automatic    // resuelve a .all en TUIkit
```

Para colapsar/expandir con `Ctrl+B`: `@State var visibility = NavigationSplitViewVisibility.all` → alternar a `.detailOnly`.

### 4. Tamaño del terminal en una vista

**No existe `GeometryReader` ni `@Environment(\.terminalSize)`.**

El tamaño está disponible únicamente en `RenderContext` dentro de vistas que implementan el protocolo `Renderable`:

```swift
func renderToBuffer(context: RenderContext) -> FrameBuffer {
    let width = context.availableWidth   // columnas de caracteres
    let height = context.availableHeight // líneas visibles
}
```

Las vistas `View` públicas con `body: some View` **no tienen acceso directo al tamaño**. El `EditorView` deberá implementar `Renderable` (como vista privada `_EditorViewCore`) para obtener las dimensiones del viewport en cada render.

### 5. Texto invertido para el cursor

`Text` tiene `.inverted()` (en `Views/Text.swift`):

```swift
Text("X").inverted()   // rende con colores intercambiados (cursor block)
```

`TextStyle` soporta: `foregroundColor`, `backgroundColor`, `isBold`, `isItalic`, `isUnderlined`, `isStrikethrough`, `isDim`, `isBlink`, `isInverted`.

No existe `.inverted()` en `View` genérico. Para contenedores, usar `.background(.white)` + `.foregroundStyle(.black)`.

### 6. Mecanismo de estado observable

**Tipos de valor:** `@State` (en `TUIkitView/State/State.swift`), idéntico a SwiftUI. Cada mutación llama `AppState.shared.setNeedsRender()`.

**Tipos de referencia:** macro `@Observable` de Swift + `.environment(_:)` / `@Environment(ObjectType.self)`:

```swift
@Observable
class EditorState {
    var buffer: TextBuffer = TextBuffer()
}

// En la raíz:
ContentView().environment(EditorState())

// En vistas hijas:
@Environment(EditorState.self) var editorState
```

También disponible: `@Environment(\.keyPath)` para `EnvironmentKey`-based values (e.g. `@Environment(\.statusBar) var statusBar`).

---

## Tabla de atajos (referencia)

| Acción | Atajo |
|--------|-------|
| Salir | `Ctrl+Q` |
| Guardar | `Ctrl+S` |
| Colapsar/expandir sidebar | `Ctrl+B` |
| Cambiar foco | `Tab` / `Shift+Tab` |
| Marcar selección | `Ctrl+^` |
| Copiar | `Alt+C` |
| Cortar | `Ctrl+K` |
| Pegar | `Ctrl+U` |
| Buscar | `Ctrl+W` |
| Ir a línea | `Ctrl+G` |
| Buscar y reemplazar | `Ctrl+R` |
| Cancelar | `Esc` |
