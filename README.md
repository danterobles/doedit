# doedit

Editor TUI de archivos de configuración, estilo nano. Construido en Swift puro sobre [TUIkit](https://github.com/phranck/TUIkit), sin ncurses ni dependencias C.

---

## Requisitos

- macOS 15+ (o Linux con Swift 6.0+)
- Swift 6.0+

---

## Instalación

```bash
git clone https://github.com/danterobles/doedit
cd doedit
swift build -c release
```

El binario queda en `.build/release/doedit`. Para instalarlo globalmente:

```bash
cp .build/release/doedit /usr/local/bin/
# o en Linux sin permisos de root:
cp .build/release/doedit ~/.local/bin/
```

---

## Uso

```bash
doedit                    # abre el directorio actual
doedit /ruta/al/dir       # abre un directorio específico
```

Al arrancar, el panel lateral muestra los archivos del directorio indicado. Navega con las flechas y pulsa `Enter` para abrir un archivo. El panel se puede colapsar con `Ctrl+B` para ganar espacio en el editor.

---

## Atajos de teclado

### Globales

| Acción | Atajo |
|--------|-------|
| Guardar | `Ctrl+S` |
| Salir | `Ctrl+Q` |
| Colapsar / expandir sidebar | `Ctrl+B` |
| Cambiar foco sidebar ↔ editor | `Tab` / `Shift+Tab` |

### Edición

| Acción | Atajo |
|--------|-------|
| Deshacer | `Ctrl+Z` |
| Rehacer | `Ctrl+Y` |
| Nueva línea | `Enter` |
| Borrar hacia atrás | `Backspace` |
| Borrar hacia adelante | `Supr` |
| Cortar línea (o selección activa) | `Ctrl+K` |
| Pegar | `Ctrl+U` |

### Selección y portapapeles

| Acción | Atajo |
|--------|-------|
| Iniciar / extender selección | `Shift+Flechas`, `Shift+Home`, `Shift+End` |
| Copiar selección | `Alt+C` |
| Cortar selección | `Ctrl+K` |

### Navegación

| Acción | Atajo |
|--------|-------|
| Mover cursor | Flechas |
| Inicio / fin de línea | `Home` / `End` |
| Página arriba / abajo | `PageUp` / `PageDown` |
| Ir a línea específica | `Ctrl+G` |

### Búsqueda y reemplazo

| Acción | Atajo |
|--------|-------|
| Buscar | `Ctrl+W` |
| Siguiente coincidencia | `Alt+W` |
| Coincidencia anterior | `Alt+Shift+W` |
| Buscar y reemplazar | `Ctrl+R` |
| Cerrar cualquier prompt | `Esc` |

---

## Limitaciones conocidas

- **Sin portapapeles del sistema**: copiar / pegar opera dentro de doedit únicamente; no intercambia con el portapapeles del SO.
- **Sin soporte de ratón**: navegación exclusivamente por teclado.
- **UTF-8 solamente**: archivos en otras codificaciones (Latin-1, UTF-16, etc.) son rechazados al abrirse con un aviso.
- **Archivos binarios**: detectados por la presencia de bytes nulos; se muestran en el sidebar pero no se pueden abrir.
- **Solo lectura**: los archivos sin permiso de escritura se abren en modo `RO` (indicado en la barra de estado); las teclas de edición quedan bloqueadas.
- **Pila de deshacer limitada a 50 pasos**: el estado más antiguo se descarta al superar ese límite.
- **Sin resaltado de sintaxis**: el editor es genérico; no colorea por tipo de archivo de configuración.
- **Buffer por líneas (`[String]`)**: adecuado para archivos de configuración pequeños y medianos. No optimizado para archivos de varios megabytes.
- **Linux**: el código compila con Swift 6.0 en Linux pero no está verificado en CI continua.

---

## Desarrollo

```bash
swift build          # compilación debug
swift test           # suite de tests del núcleo (40 tests)
swift run doedit .   # ejecutar en el directorio actual
```

Los tests cubren `TextBuffer`, `Selection` y búsqueda / reemplazo sin necesidad de terminal.

---

## Arquitectura

```
Sources/
├── App.swift               # @main, punto de entrada
├── Model/                  # doeditCore (librería importable por tests)
│   ├── TextBuffer.swift    # motor de edición: líneas, cursor, undo/redo
│   ├── Selection.swift     # rango de selección y portapapeles
│   ├── SearchEngine.swift  # búsqueda case-sensitive / insensitive
│   ├── EditorState.swift   # estado global observable
│   ├── FileEntry.swift     # descriptor de archivo en el sidebar
│   └── FileService.swift   # leer / listar archivos, detección de binarios
├── Views/
│   ├── RootView.swift      # NavigationSplitView + atajos globales
│   ├── SidebarView.swift   # lista de archivos
│   ├── EditorView.swift    # render del buffer con cursor y scroll
│   ├── GoToLinePrompt.swift
│   ├── SearchPrompt.swift
│   └── ReplacePrompt.swift
└── Input/
    └── EditorHandler.swift # dispatch de teclas al buffer
Tests/
├── TextBufferTests.swift   # 16 tests
├── SelectionTests.swift    # 12 tests
└── SearchReplaceTests.swift# 12 tests
```

El modelo (`Sources/Model/`) está desacoplado de TUIkit y compilado como librería independiente (`doeditCore`), lo que permite ejecutar los tests sin terminal.

---

<details>
<summary>Discovery de API de TUIkit (Fase 0 — referencia interna)</summary>

### 1. Firma de `.onKeyPress()` y modificadores

```swift
// Captura cualquier tecla; devolver true consume el evento
func onKeyPress(_ handler: @escaping (KeyEvent) -> Bool) -> some View

// KeyEvent
public struct KeyEvent: Equatable, Sendable {
    public let key: Key
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

`Ctrl+S` llega como `KeyEvent(key: .character("s"), ctrl: true)`.

### 2. Ctrl+S y Ctrl+Q llegan a la app

`Terminal.enableRawMode()` deshabilita `IXON` explícitamente:

```swift
raw.c_iflag &= ~TermFlag(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
```

`Ctrl+S` (0x13) y `Ctrl+Q` (0x11) no son interceptados por el terminal. El shortcut de salida se configura con `statusBar.quitShortcut = .ctrlQ`.

### 3. NavigationSplitView

```swift
NavigationSplitView(
    columnVisibility: $visibility,   // .all / .detailOnly
    sidebar: { SidebarView() },
    detail: { EditorView() }
)
```

### 4. Tamaño del terminal

Solo disponible en `RenderContext` dentro de vistas `Renderable`:

```swift
func renderToBuffer(context: RenderContext) -> FrameBuffer {
    let width  = context.availableWidth
    let height = context.availableHeight
}
```

Las vistas públicas con `body: some View` no tienen acceso directo. `EditorView` usa una vista privada `_EditorViewCore: Renderable`.

### 5. Cursor (texto invertido)

```swift
Text("X").inverted()   // intercambia fg/bg — cursor block
```

### 6. Estado observable

`@Observable` (macro Swift) + `@State` de TUIkit para tipos valor. Cada mutación llama `AppState.shared.setNeedsRender()` automáticamente.

</details>
