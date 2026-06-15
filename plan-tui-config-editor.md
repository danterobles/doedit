# Plan de Implementación: Editor TUI de Archivos de Configuración (estilo nano) con TUIkit

> Documento de especificación ejecutable. Destinatario: agente Claude Sonnet 4.6 (Claude Code).
> Objetivo del agente: construir, fase por fase, una utilería de terminal en Swift sobre la librería TUIkit, validando cada fase antes de avanzar.

---

## 0. Contexto y objetivo

Construir una utilería TUI para macOS y Linux: un editor ligero estilo `nano` para editar archivos de configuración de forma rápida. Debe compilar a un binario nativo, ligero y portable.

Librería base obligatoria: **TUIkit** (`phranck/TUIkit`, https://tuikit.dev). Framework declarativo estilo SwiftUI para terminales, Swift puro, sin ncurses ni dependencias C. Requiere Swift 6.0+, macOS 14+ o Linux.

Nombre de trabajo del binario: `cfgedit` (ajustable).

### Requisitos funcionales

1. Panel lateral (sidebar) de archivos, colapsable.
2. Editar un archivo (motor de edición de texto multilínea).
3. Atajos: `Ctrl+S` para guardar, `Ctrl+Q` para salir.
4. Copiar y mover texto (selección + copiar/cortar/pegar).
5. Buscar dentro del archivo.
6. Ir a una línea específica.
7. Buscar y reemplazar.

---

## 1. Evaluación de la librería frente a los requisitos

Resultado del análisis de la documentación y el README de TUIkit. **Esto define la arquitectura, leerlo antes de codificar.**

| # | Requisito | ¿La librería lo provee? | Estrategia |
|---|-----------|--------------------------|------------|
| 1 | Sidebar colapsable | Sí: `NavigationSplitView` + `List` | Usar componente nativo + estado de visibilidad |
| 2 | Editar archivo (multilínea) | **No existe componente** (solo `TextField` de una línea) | **Motor de edición propio** (núcleo del proyecto) |
| 3 | Atajos Ctrl+S / Ctrl+Q | Sí: `.onKeyPress()` con modificadores + `StatusBar` | Captura de teclas + barra de estado contextual |
| 4 | Copiar y mover texto | No (deriva del motor propio) | Selección + portapapeles interno + cut/copy/paste |
| 5 | Buscar | Parcial: `TextField` para el prompt | Prompt + lógica de búsqueda propia |
| 6 | Ir a línea | Parcial: `TextField` para el prompt | Prompt numérico + reposicionar cursor |
| 7 | Buscar y reemplazar | Parcial: `TextField` para prompts | Dos prompts + reemplazo actual / todos |

### Componentes de TUIkit que se usarán

- **Layout / chrome**: `NavigationSplitView`, `List`, `Section`, `ForEach`, `VStack`, `HStack`, `ZStack`, `Divider`, `Spacer`.
- **Captura de teclado**: modificador `.onKeyPress()` (soporta ctrl, alt, shift y teclas F1–F12).
- **Barra de estado**: `StatusBar` / `.statusBarItems { StatusBarItem(shortcut:label:) }` (estilos `.compact` y `.bordered`).
- **Prompts y avisos**: `TextField` (entrada de una línea), `Dialog`, `Alert`, `Panel`, `Box`.
- **Estado y ciclo de vida**: `@State`, `@Environment`, `@AppStorage`, `.onAppear()`, `.task()`.
- **Estilo**: modificadores de texto (`.bold()`, `.foregroundStyle()`, invertido para el cursor), paletas (`SystemPalette`), bordes.
- **i18n**: TUIkit incluye español nativo (`LocalizationKey`); úsese para los textos de UI.

### Restricciones y riesgos conocidos (atender en la Fase 0)

- **TUIkit es WORK IN PROGRESS (v0.6.0)**: las firmas exactas de API pueden diferir del README. No asumir; verificar contra el código fuente / DocC en la fase de discovery.
- **No hay editor multilínea**: el motor de edición se construye desde cero. Es el mayor esfuerzo del proyecto.
- **Ctrl+S y Ctrl+Q son XON/XOFF (control de flujo) en terminales POSIX**: por defecto el terminal los intercepta y nunca llegan a la app. Hay que asegurar que el modo raw deshabilite `IXON` en `termios` para que esas teclas lleguen a `.onKeyPress()`. Verificar si la clase `Terminal` de TUIkit ya lo hace; si no, documentar el workaround o, en última instancia, ofrecer atajos alternativos configurables.
- **Ctrl+C / Ctrl+Z / Ctrl+\\**: suelen generar señales (SIGINT/SIGTSTP/SIGQUIT). No usarlos para copiar/pegar. Se adopta el esquema estilo nano (ver tabla de atajos).
- **Tamaño del viewport**: el motor necesita saber cuántas líneas/columnas hay disponibles para render y scroll. Confirmar cómo TUIkit expone el tamaño del terminal (Environment, clase `Terminal`, o equivalente a `GeometryReader`). Si no existe, leer tamaño vía `ioctl`/`Terminal` y propagarlo por Environment.

---

## 2. Decisiones técnicas

- **Lenguaje**: Swift 6.0+, concurrencia estricta (TUIkit es `Sendable`-compliant).
- **Gestor de paquetes**: Swift Package Manager.
- **Dependencia**: TUIkit por SPM. Fijar a la release estable `from: "0.6.0"`; si una API requerida no está publicada, usar `branch: "main"` y dejar comentado el motivo.
- **Modelo de buffer**: para archivos de configuración (tamaño pequeño/medio) usar `[String]` (array de líneas). Suficiente y simple; no se necesita rope/gap buffer en v1. Documentar el límite y dejar la abstracción aislada por si hay que cambiarla.
- **Idioma de la UI**: español por defecto vía i18n de TUIkit.
- **Sin emojis** en la UI ni en mensajes (estilo de producto del autor).

---

## 3. Estructura del proyecto

```
cfgedit/
├── Package.swift
├── README.md
└── Sources/
    └── cfgedit/
        ├── main.swift                 # @main App, escena raíz
        ├── App/
        │   └── EditorApp.swift         # App protocol, WindowGroup, paleta
        ├── Model/
        │   ├── TextBuffer.swift        # núcleo de edición (líneas, cursor, mutaciones)
        │   ├── Selection.swift         # rango de selección y portapapeles
        │   ├── EditorState.swift       # @Observable/estado global del editor
        │   └── FileService.swift       # listar dir, leer, escribir archivos
        ├── Views/
        │   ├── RootView.swift          # NavigationSplitView (sidebar + editor)
        │   ├── SidebarView.swift       # List de archivos, colapsable
        │   ├── EditorView.swift        # render del buffer + cursor + scroll
        │   ├── StatusBarView.swift     # atajos contextuales
        │   └── Prompts/
        │       ├── SearchPrompt.swift  # buscar
        │       ├── GoToLinePrompt.swift# ir a línea
        │       └── ReplacePrompt.swift # buscar y reemplazar
        └── Input/
            └── KeyBindings.swift       # mapa central de atajos + dispatch
└── Tests/
    └── cfgeditTests/
        ├── TextBufferTests.swift
        ├── SelectionTests.swift
        └── SearchReplaceTests.swift
```

### Package.swift (referencia, verificar versión)

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "cfgedit",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIkit.git", from: "0.6.0")
        // Si una API requerida no está en 0.6.0, usar:
        // .package(url: "https://github.com/phranck/TUIkit.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "cfgedit",
            dependencies: ["TUIkit"]
        ),
        .testTarget(
            name: "cfgeditTests",
            dependencies: ["cfgedit"]
        )
    ]
)
```

---

## 4. Modelo de datos (núcleo)

Diseño de referencia. Ajustar nombres a la API real de TUIkit para el binding de estado (`@State`, `@Observable`, o el mecanismo que exponga la versión instalada).

### TextBuffer

```swift
struct CursorPosition: Equatable {
    var line: Int      // 0-based
    var column: Int    // 0-based, en caracteres (no bytes)
}

final class TextBuffer {
    private(set) var lines: [String]
    var cursor: CursorPosition
    var scrollOffset: Int          // primera línea visible
    var horizontalOffset: Int      // primera columna visible
    private(set) var isDirty: Bool
    var filePath: String?

    // Mutaciones básicas
    func insert(_ char: Character)         // inserta en cursor, marca dirty
    func insertNewline()                   // parte la línea actual en el cursor
    func deleteBackward()                  // backspace, une líneas si col == 0
    func deleteForward()                   // suprimir
    func insert(text: String)             // para pegar bloques multilínea

    // Movimiento (clamp a límites válidos)
    func moveLeft(); func moveRight()
    func moveUp(); func moveDown()
    func moveLineStart(); func moveLineEnd()
    func moveTo(line: Int, column: Int)    // base para "ir a línea"
    func pageUp(viewportHeight: Int); func pageDown(viewportHeight: Int)

    // Scroll: recalcular scrollOffset/horizontalOffset para mantener el cursor visible
    func ensureCursorVisible(viewportHeight: Int, viewportWidth: Int)
}
```

Reglas clave:
- Trabajar siempre en unidades de `Character` (no `UInt8`) para evitar romper UTF-8/acentos.
- Todo movimiento hace clamp a rangos válidos (sin cursor fuera del texto).
- Cada mutación marca `isDirty = true` y dispara re-render vía el estado observable.

### Selection y portapapeles

```swift
struct Selection {
    var anchor: CursorPosition   // donde se "marcó"
    var head: CursorPosition     // posición actual del cursor
    var isActive: Bool
    func normalized() -> (start: CursorPosition, end: CursorPosition)
}

final class Clipboard {
    var content: String = ""     // soporta multilínea
}
```

Operaciones (requisito 4 "copiar y mover"):
- **Marcar selección**: fija `anchor` en el cursor y activa la selección; al mover el cursor, `head` la sigue.
- **Copiar**: `clipboard.content = textoSeleccionado`; mantiene el texto.
- **Cortar**: copia y luego borra el rango (esto cubre "mover": cortar + reubicar cursor + pegar).
- **Pegar**: inserta `clipboard.content` en el cursor (maneja saltos de línea).

---

## 5. Mapa de atajos

Esquema base estilo nano, adaptado para evitar teclas reservadas por el terminal. Centralizar en `KeyBindings.swift` y mostrarlo en la `StatusBar`. Debe ser fácilmente reconfigurable.

| Acción | Atajo | Notas |
|--------|-------|-------|
| Guardar | `Ctrl+S` | Requiere `IXON` deshabilitado en termios |
| Salir | `Ctrl+Q` | Si hay cambios sin guardar, pedir confirmación |
| Colapsar/expandir sidebar | `Ctrl+B` | Toggle de visibilidad de la columna |
| Cambiar foco sidebar/editor | `Tab` / `Shift+Tab` | Sistema de foco de TUIkit |
| Mover cursor | Flechas, `Home`, `End`, `PageUp`, `PageDown` | |
| Marcar inicio de selección | `Ctrl+^` (Ctrl+6) | Estilo nano "set mark" |
| Copiar | `Alt+C` | No usar Ctrl+C (SIGINT) |
| Cortar | `Ctrl+K` | Cortar selección (o línea si no hay selección) |
| Pegar | `Ctrl+U` | |
| Buscar | `Ctrl+W` | Abre prompt de búsqueda |
| Buscar siguiente / anterior | `Alt+W` / `Alt+Shift+W` | Sobre la última búsqueda |
| Ir a línea | `Ctrl+G` | Abre prompt numérico |
| Buscar y reemplazar | `Ctrl+R` | Abre prompt de reemplazo |
| Cancelar prompt actual | `Esc` | Cierra cualquier overlay |

Nota: confirmar en Fase 0 qué combinaciones reporta efectivamente `.onKeyPress()` en macOS y Linux. Si `Alt+letra` o `Ctrl+^` no llegan de forma fiable, definir alternativas (p. ej. teclas de función F2 guardar, F10 salir) y dejarlas configurables.

---

## 6. Plan por fases

Cada fase termina con `swift build` y `swift run` exitosos y una verificación manual del criterio de aceptación. No avanzar a la siguiente fase sin cumplir la actual.

### Fase 0 — Scaffold y discovery (bloqueante)

Objetivo: tener el proyecto compilando y **resolver las incógnitas de API antes de escribir el motor**.

Tareas:
1. `swift package init` o `tuikit init`, configurar `Package.swift` con la dependencia TUIkit.
2. App mínima: `WindowGroup` con un `Text("cfgedit")` y un `StatusBarItem` de salida. `swift run` debe mostrarlo y salir con `Ctrl+Q`/`q`.
3. Discovery (leer el código fuente de TUIkit en `~/.build` o el repo, no solo el README) y dejar hallazgos en `README.md`:
   - Firma exacta de `.onKeyPress()` y cómo expone modificadores ctrl/alt/shift.
   - Si `Ctrl+S`/`Ctrl+Q` llegan a la app (probar empíricamente). Si no, localizar dónde `Terminal` configura `termios` y confirmar `IXON`.
   - API real de `NavigationSplitView` (init, `columnVisibility`, cómo se colapsa la columna).
   - Cómo obtener el tamaño del terminal (ancho/alto) desde una vista.
   - Si el texto invertido (`.inverted` o equivalente) está disponible para dibujar el cursor.
   - Mecanismo de estado observable que dispara re-render (`@State` con clases, `@Observable`, etc.).

Criterio de aceptación: la app corre, sale con un atajo, y el `README.md` documenta las 6 incógnitas anteriores con la respuesta verificada.

### Fase 1 — Sidebar de archivos colapsable (requisito 1)

Tareas:
1. `FileService`: listar el contenido de un directorio (archivos y subdirectorios), con filtro opcional por extensiones de config (`.conf`, `.cfg`, `.ini`, `.yaml`, `.yml`, `.toml`, `.env`, `.json`, etc.) y opción de mostrar todos.
2. `SidebarView`: `List` dentro de la columna lateral de `NavigationSplitView`, navegación con flechas/`Enter`.
3. Toggle de colapso con `Ctrl+B` controlando la visibilidad de la columna.
4. Determinar el directorio inicial: argumento de línea de comandos (`cfgedit /ruta`) o `cwd`.

Criterio de aceptación: se ve la lista de archivos, se navega con teclado, `Ctrl+B` colapsa y expande el panel.

### Fase 2 — Motor de edición (requisito 2)

Esta es la fase central. Sin componente nativo: todo propio.

Tareas:
1. Implementar `TextBuffer` completo (sección 4): carga desde archivo, mutaciones, movimiento, scroll.
2. `FileService.read(path:)` que detecte el fin de línea (LF/CRLF) y lo preserve al guardar.
3. `EditorView`: render de las líneas visibles según `scrollOffset` y alto del viewport; cada línea es un `Text`. Dibujar el cursor invirtiendo el carácter en su posición. Dibujar números de línea a la izquierda (opcional, recomendado).
4. Conectar `.onKeyPress()` para: inserción de caracteres imprimibles, `Enter` (nueva línea), `Backspace`, `Supr`, flechas, `Home`/`End`, `PageUp`/`PageDown`.
5. Manejar scroll vertical y horizontal (`ensureCursorVisible`).
6. Indicador de "modificado" en la barra de estado/título cuando `isDirty`.

Criterio de aceptación: abrir un archivo desde el sidebar, escribir, borrar, navegar por todo el contenido (incluyendo archivos más largos que la pantalla) con el cursor siempre visible, y respetar acentos/UTF-8.

### Fase 3 — Guardar y salir (requisito 3)

Tareas:
1. `Ctrl+S`: escribir el buffer a disco preservando el fin de línea original; limpiar `isDirty`; feedback (toast/notification de TUIkit).
2. `Ctrl+Q`: si `isDirty`, abrir `Dialog`/`Alert` de confirmación (Guardar / Descartar / Cancelar); si no, salir directo.
3. Manejo de errores de escritura (permisos, ruta inexistente) con aviso claro, sin crash.

Criterio de aceptación: editar, `Ctrl+S` persiste cambios en disco, `Ctrl+Q` con cambios pendientes pide confirmación.

### Fase 4 — Copiar y mover texto (requisito 4)

Tareas:
1. Implementar `Selection` y el resaltado visual del rango seleccionado en `EditorView` (estilo invertido o color de fondo).
2. Marcar selección (`Ctrl+^`), copiar (`Alt+C`), cortar (`Ctrl+K`), pegar (`Ctrl+U`).
3. "Mover texto" = cortar + reubicar cursor + pegar (documentarlo como flujo).
4. Soporte de pegado multilínea correcto.

Criterio de aceptación: seleccionar un bloque, copiarlo y pegarlo en otra parte; cortar y mover un bloque a otra línea.

### Fase 5 — Buscar e ir a línea (requisitos 5 y 6)

Tareas:
1. `SearchPrompt`: overlay con `TextField`; búsqueda desde la posición del cursor, con wrap-around. Resaltar coincidencia y mover el cursor a ella.
2. Navegar coincidencias siguiente/anterior (`Alt+W` / `Alt+Shift+W`).
3. Opciones: sensible a mayúsculas (toggle). (Regex opcional, no requerido en v1.)
4. `GoToLinePrompt`: `TextField` numérico; validar y hacer clamp; mover cursor y ajustar scroll.

Criterio de aceptación: buscar un término, saltar entre coincidencias; ir a una línea por número y aterrizar en ella centrada/visible.

### Fase 6 — Buscar y reemplazar (requisito 7)

Tareas:
1. `ReplacePrompt`: dos campos (buscar / reemplazar).
2. Reemplazar la coincidencia actual (con confirmación) y "reemplazar todo" con conteo de reemplazos.
3. Marcar `isDirty` y permitir deshacer la operación si se implementa undo (ver Fase 7).

Criterio de aceptación: reemplazar una ocurrencia y todas, con conteo correcto y respetando mayúsculas según el toggle.

### Fase 7 — Pulido, robustez y pruebas

Tareas:
1. `StatusBarView` contextual: mostrar los atajos relevantes según el modo (edición, prompt, sidebar).
2. (Recomendado) Undo/redo básico (pila de operaciones o snapshots de líneas).
3. Paleta/tema vía `SystemPalette`; textos en español por i18n.
4. Manejo de archivos de solo lectura, archivos binarios (rechazar con aviso), archivos vacíos, líneas muy largas.
5. Tests unitarios del modelo (no requieren terminal): `TextBuffer`, `Selection`, búsqueda y reemplazo. Apuntar a cobertura del núcleo.
6. `README.md` final: instalación, uso, tabla de atajos, limitaciones conocidas.

Criterio de aceptación: `swift test` en verde para el núcleo; la app maneja casos límite sin crash.

---

## 7. Pruebas

- **Unitarias (sin TUI)**: toda la lógica de `TextBuffer`, `Selection`, búsqueda y reemplazo debe ser testeable sin renderizar. Mantener el modelo desacoplado de las vistas para lograrlo. Usar Swift Testing (`@Test`, `#expect`), igual que TUIkit.
- **Manual por fase**: cada fase define su criterio de aceptación verificable a mano en una terminal real (macOS y, si es posible, Linux).
- Casos límite obligatorios: archivo vacío, una sola línea sin salto final, CRLF vs LF, UTF-8 con acentos y emojis de ancho variable, línea más ancha que la pantalla, archivo más largo que la pantalla, archivo sin permiso de escritura.

---

## 8. Construir y ejecutar

```bash
# Compilar
swift build -c release

# Ejecutar en desarrollo
swift run cfgedit /ruta/a/tus/configs

# Binario release
.build/release/cfgedit /ruta/a/tus/configs

# Pruebas
swift test
```

Distribución: el binario de `.build/release/` es portable dentro de la misma plataforma. Para instalación tipo CLI, copiar a `/usr/local/bin` o `~/.local/bin`.

---

## 9. Definición de "terminado" (v1)

- [ ] Compila y corre en macOS (y Linux si está disponible).
- [ ] Sidebar de archivos colapsable funcional (Ctrl+B).
- [ ] Edición multilínea completa con cursor, scroll y soporte UTF-8.
- [ ] Ctrl+S guarda preservando fin de línea; Ctrl+Q sale con confirmación si hay cambios.
- [ ] Selección + copiar + cortar + pegar (y por tanto mover) operativos.
- [ ] Buscar con navegación entre coincidencias.
- [ ] Ir a línea por número.
- [ ] Buscar y reemplazar (actual y todos, con conteo).
- [ ] Barra de estado contextual con atajos visibles.
- [ ] Tests del núcleo en verde.
- [ ] README con atajos y limitaciones.

---

## 10. Notas para el agente ejecutor

- **No asumas la API de TUIkit por el README**: es WORK IN PROGRESS. Verifica firmas reales en el código fuente resuelto por SPM antes de cada fase que toque la librería.
- **Resuelve la Fase 0 por completo antes de avanzar.** El asunto de `IXON`/`Ctrl+S` y el tamaño del viewport puede cambiar decisiones de diseño.
- **Mantén el motor de edición desacoplado de las vistas** para poder testearlo sin terminal.
- **Si un atajo no es capturable de forma fiable** en la plataforma, define una alternativa y documéntala; no bloquees el avance.
- **Idioma de la UI en español, sin emojis.**
- Entrega cada fase como un commit verificable con su criterio de aceptación cumplido.
