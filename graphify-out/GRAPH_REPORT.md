# Graph Report - .  (2026-06-22)

## Corpus Check
- 6 files · ~9,730 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 280 nodes · 426 edges · 19 communities (14 shown, 5 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 42 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Text Buffer Core|Text Buffer Core]]
- [[_COMMUNITY_Editor Input & Traits|Editor Input & Traits]]
- [[_COMMUNITY_Plan & TUI Architecture|Plan & TUI Architecture]]
- [[_COMMUNITY_TUIkit Rendering Layer|TUIkit Rendering Layer]]
- [[_COMMUNITY_Selection & Cursor Model|Selection & Cursor Model]]
- [[_COMMUNITY_TextBuffer Test Suite|TextBuffer Test Suite]]
- [[_COMMUNITY_EditorState & Search Core|EditorState & Search Core]]
- [[_COMMUNITY_File IO & Error Types|File I/O & Error Types]]
- [[_COMMUNITY_SearchReplace Tests|Search/Replace Tests]]
- [[_COMMUNITY_File Open & Read-Only|File Open & Read-Only]]
- [[_COMMUNITY_Key Dispatch & Mutations|Key Dispatch & Mutations]]
- [[_COMMUNITY_Clipboard & Focus|Clipboard & Focus]]
- [[_COMMUNITY_App Entry Point|App Entry Point]]
- [[_COMMUNITY_TUIkit Patches|TUIkit Patches]]
- [[_COMMUNITY_Replace Operations|Replace Operations]]
- [[_COMMUNITY_Directory Listing|Directory Listing]]
- [[_COMMUNITY_Package Config|Package Config]]
- [[_COMMUNITY_Search Execution|Search Execution]]

## God Nodes (most connected - your core abstractions)
1. `TextBuffer` - 44 edges
2. `CursorPosition` - 32 edges
3. `EditorState` - 22 edges
4. `TextBufferTests` - 18 edges
5. `Snapshot` - 13 edges
6. `SelectionTests` - 13 edges
7. `EditorHandler` - 12 edges
8. `Selection` - 12 edges
9. `RootView` - 12 edges
10. `SearchReplaceTests` - 12 edges

## Surprising Connections (you probably didn't know these)
- `Internal Clipboard (app-scoped, no OS integration)` --rationale_for--> `EditorHandler`  [INFERRED]
  README.md → Sources/Input/EditorHandler.swift
- `doeditCore Library (model decoupled from TUIkit)` --rationale_for--> `EditorState`  [INFERRED]
  README.md → Sources/Model/EditorState.swift
- `Line-Based Buffer ([String] array)` --rationale_for--> `TextBuffer`  [INFERRED]
  README.md → Sources/Model/TextBuffer.swift
- `_EditorViewCore` --implements--> `Renderable Protocol Pattern`  [INFERRED]
  Sources/Views/EditorView.swift → plan-tui-config-editor.md
- `doedit README` --references--> `EditorState`  [EXTRACTED]
  README.md → Sources/Model/EditorState.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Editor Key Dispatch Flow: RootView → EditorHandler → TextBuffer** — views_rootview_rootview, input_editorhandler_editorhandler, model_textbuffer_textbuffer [INFERRED 0.95]
- **Search/Replace Pipeline: EditorState coordinates TextBuffer.search and TextBuffer.replaceInLine** — model_editorstate_runsearch, model_editorstate_replacecurrentmatch, model_textbuffer_replaceinline [EXTRACTED 1.00]
- **Undo/Redo Snapshot Mechanism: Snapshot struct, undoStack, redoStack** — model_textbuffer_snapshot, model_textbuffer_undo, model_textbuffer_redo [EXTRACTED 1.00]

## Communities (19 total, 5 thin omitted)

### Community 0 - "Text Buffer Core"
Cohesion: 0.08
Nodes (13): Character, Line-Based Buffer ([String] array), Read-Only Mode (RO flag, mutation blocking), Undo/Redo stack pattern, Undo/Redo Stack Pattern (max 50 snapshots), Snapshot, TextBuffer, Range (+5 more)

### Community 1 - "Editor Input & Traits"
Cohesion: 0.09
Nodes (21): Search and Replace feature, Viewport scroll / cursor visibility, Equatable, Hashable, Identifiable, FileEntry, MatchPosition, TextBuffer (+13 more)

### Community 2 - "Plan & TUI Architecture"
Cohesion: 0.08
Nodes (24): IXON Raw Mode Rationale, NotificationService, Phase 0 - Scaffold and Discovery, Phase 1 - Sidebar, Phase 3 - Save and Quit, Phase 4 - Copy and Move Text, Phase 5 - Search and Go To Line, Phase 6 - Find and Replace (+16 more)

### Community 3 - "TUIkit Rendering Layer"
Cohesion: 0.09
Nodes (24): FrameBuffer, Never, Phase 2 - Text Editing Engine, Renderable Protocol Pattern, TextBuffer [String] Array Design Rationale, Renderable, RenderContext, Clipboard (+16 more)

### Community 4 - "Selection & Cursor Model"
Cohesion: 0.16
Nodes (6): Comparable, Selection, CursorPosition, Bool, Int, SelectionTests

### Community 6 - "EditorState & Search Core"
Cohesion: 0.18
Nodes (7): doeditCore Library (model decoupled from TUIkit), MatchPosition, EditorState, FileEntry, Int, String, TextBuffer

### Community 7 - "File I/O & Error Types"
Cohesion: 0.16
Nodes (12): Error, LineEnding, LocalizedError, FileService, FileServiceError, binaryFile, doedit README, Set (+4 more)

### Community 9 - "File Open & Read-Only"
Cohesion: 0.23
Nodes (11): Binary File Detection via Null Bytes, EditorState, EditorState.nextMatch, EditorState.openFile, EditorState.prevMatch, EditorState.saveCurrentBuffer, FileService.read, TextBuffer.serialize (+3 more)

### Community 10 - "Key Dispatch & Mutations"
Cohesion: 0.21
Nodes (12): EditorHandler.handleKeyEvent, EditorState.goToLine, TextBuffer.cutLine, TextBuffer.deleteBackward, TextBuffer.deleteForward, TextBuffer.deleteSelection, TextBuffer.ensureCursorVisible, TextBuffer.insert(char) (+4 more)

### Community 11 - "Clipboard & Focus"
Cohesion: 0.25
Nodes (9): Clipboard, Internal Clipboard (app-scoped, no OS integration), Focusable, EditorHandler, KeyEvent, Bool, Clipboard, String (+1 more)

### Community 12 - "App Entry Point"
Cohesion: 0.25
Nodes (6): App, Scene, settings.json (Claude hooks config), doeditApp, String, App protocol (TUIkit)

### Community 13 - "TUIkit Patches"
Cohesion: 0.36
Nodes (5): Row Truncation with Ellipsis, Sidebar Row Overflow Fix, TUIkit SPM Checkout (.build/checkouts/TUIkit), TUIkit _ListCore, apply-patches.sh script

### Community 14 - "Replace Operations"
Cohesion: 1.00
Nodes (3): EditorState.replaceAllMatches, EditorState.replaceCurrentMatch, TextBuffer.replaceInLine

## Knowledge Gaps
- **59 isolated node(s):** `Scene`, `String`, `KeyEvent`, `Bool`, `FileEntry` (+54 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TextBuffer` connect `Text Buffer Core` to `Editor Input & Traits`, `Selection & Cursor Model`, `EditorState & Search Core`, `File I/O & Error Types`, `File Open & Read-Only`, `Clipboard & Focus`?**
  _High betweenness centrality (0.296) - this node is a cross-community bridge._
- **Why does `CursorPosition` connect `Selection & Cursor Model` to `Text Buffer Core`, `Editor Input & Traits`, `TextBuffer Test Suite`, `EditorState & Search Core`?**
  _High betweenness centrality (0.222) - this node is a cross-community bridge._
- **Why does `EditorState` connect `EditorState & Search Core` to `Text Buffer Core`, `Editor Input & Traits`, `File Open & Read-Only`, `File I/O & Error Types`?**
  _High betweenness centrality (0.188) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `TextBuffer` (e.g. with `Line-Based Buffer ([String] array)` and `Read-Only Mode (RO flag, mutation blocking)`) actually correct?**
  _`TextBuffer` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 16 inferred relationships involving `CursorPosition` (e.g. with `.jumpToCurrentMatch()` and `.containsInsideSelection()`) actually correct?**
  _`CursorPosition` has 16 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Scene`, `String`, `KeyEvent` to the rest of the system?**
  _66 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Text Buffer Core` be split into smaller, more focused modules?**
  _Cohesion score 0.08478513356562137 - nodes in this community are weakly interconnected._