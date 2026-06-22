# Graph Report - .  (2026-06-15)

## Corpus Check
- Corpus is ~7,912 words - fits in a single context window. You may not need a graph.

## Summary
- 184 nodes · 292 edges · 11 communities (10 shown, 1 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.86)
- Token cost: 8,500 input · 2,100 output

## Community Hubs (Navigation)
- [[_COMMUNITY_TextBuffer Core Engine|TextBuffer Core Engine]]
- [[_COMMUNITY_Editor State & Input|Editor State & Input]]
- [[_COMMUNITY_Implementation Plan|Implementation Plan]]
- [[_COMMUNITY_TUI Render Pipeline|TUI Render Pipeline]]
- [[_COMMUNITY_Search & Navigation|Search & Navigation]]
- [[_COMMUNITY_Key Input Handler|Key Input Handler]]
- [[_COMMUNITY_App Entry Point|App Entry Point]]
- [[_COMMUNITY_File IO|File I/O]]
- [[_COMMUNITY_Go-to-Line Prompt|Go-to-Line Prompt]]
- [[_COMMUNITY_Package Config|Package Config]]

## God Nodes (most connected - your core abstractions)
1. `TextBuffer` - 38 edges
2. `EditorState` - 18 edges
3. `CursorPosition` - 15 edges
4. `Snapshot` - 12 edges
5. `Selection` - 11 edges
6. `_EditorViewCore` - 11 edges
7. `Plan TUI Config Editor` - 10 edges
8. `EditorHandler` - 9 edges
9. `Int` - 9 edges
10. `String` - 9 edges

## Surprising Connections (you probably didn't know these)
- `_EditorViewCore` --implements--> `Renderable Protocol Pattern`  [INFERRED]
  Sources/Views/EditorView.swift → plan-tui-config-editor.md
- `replaceAll` --references--> `NotificationService`  [EXTRACTED]
  Sources/Views/ReplacePrompt.swift → plan-tui-config-editor.md
- `doedit README` --references--> `Plan TUI Config Editor`  [INFERRED]
  README.md → plan-tui-config-editor.md
- `phase-check skill` --references--> `Plan TUI Config Editor`  [EXTRACTED]
  .claude/skills/phase-check/SKILL.md → plan-tui-config-editor.md
- `run skill` --references--> `doedit README`  [INFERRED]
  .claude/skills/run/SKILL.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Core Editor Triad: EditorHandler + TextBuffer + EditorState** — input_editorhandler, model_textbuffer, model_editorstate [INFERRED 0.95]
- **Search/Replace Flow: EditorState + SearchEngine + TextBuffer** — model_editorstate, model_searchengine, model_textbuffer [EXTRACTED 1.00]
- **Undo/Redo Snapshot Mechanism: TextBuffer + Snapshot + UndoRedo concept** — model_textbuffer, model_textbuffer_snapshot, concept_undoredo [EXTRACTED 1.00]
- **Modal Overlay System: RootView hosts SearchPrompt, GoToLinePrompt, ReplacePrompt as modals** — views_rootview, views_searchprompt, views_gotolineprompt, views_replaceprompt [EXTRACTED 1.00]
- **Editor Render Pipeline: EditorView delegates to _EditorViewCore which implements Renderable to access viewport dimensions** — views_editorview, views_editorview_core, views_editorview_rendertobuffer [EXTRACTED 1.00]
- **View layer implements plan phases: sidebar (Phase 1), editor (Phase 2), save/quit (Phase 3), search/goto (Phase 5), replace (Phase 6)** — views_rootview, views_sidebarview, views_editorview [INFERRED 0.85]

## Communities (11 total, 1 thin omitted)

### Community 0 - "TextBuffer Core Engine"
Cohesion: 0.10
Nodes (9): Character, Undo/Redo stack pattern, Snapshot, TextBuffer, Selection, Bool, Int, Range (+1 more)

### Community 1 - "Editor State & Input"
Cohesion: 0.09
Nodes (26): Comparable, Search and Replace feature, Viewport scroll / cursor visibility, Equatable, Hashable, Identifiable, FileEntry, MatchPosition (+18 more)

### Community 2 - "Implementation Plan"
Cohesion: 0.07
Nodes (29): IXON Raw Mode Rationale, NotificationService, Phase 0 - Scaffold and Discovery, Phase 1 - Sidebar, Phase 3 - Save and Quit, Phase 4 - Copy and Move Text, Phase 5 - Search and Go To Line, Phase 6 - Find and Replace (+21 more)

### Community 3 - "TUI Render Pipeline"
Cohesion: 0.12
Nodes (18): FrameBuffer, Never, Phase 2 - Text Editing Engine, Renderable Protocol Pattern, TextBuffer [String] Array Design Rationale, Renderable, RenderContext, Clipboard (+10 more)

### Community 4 - "Search & Navigation"
Cohesion: 0.20
Nodes (6): MatchPosition, EditorState, FileEntry, Int, String, TextBuffer

### Community 5 - "Key Input Handler"
Cohesion: 0.31
Nodes (7): Focusable, EditorHandler, KeyEvent, Bool, Clipboard, String, TextBuffer

### Community 6 - "App Entry Point"
Cohesion: 0.25
Nodes (6): App, Scene, settings.json (Claude hooks config), doeditApp, String, App protocol (TUIkit)

### Community 7 - "File I/O"
Cohesion: 0.32
Nodes (6): LineEnding, FileService, Set, Bool, FileEntry, String

### Community 8 - "Go-to-Line Prompt"
Cohesion: 0.25
Nodes (6): Binding, Bool, EditorState, GoToLinePrompt, rangeHintText, submitGoTo

## Knowledge Gaps
- **49 isolated node(s):** `Scene`, `String`, `KeyEvent`, `Bool`, `FileEntry` (+44 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `EditorHandler` connect `Key Input Handler` to `Editor State & Input`, `TUI Render Pipeline`?**
  _High betweenness centrality (0.502) - this node is a cross-community bridge._
- **Why does `TextBuffer` connect `TextBuffer Core Engine` to `Editor State & Input`?**
  _High betweenness centrality (0.292) - this node is a cross-community bridge._
- **What connects `Scene`, `String`, `KeyEvent` to the rest of the system?**
  _51 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `TextBuffer Core Engine` be split into smaller, more focused modules?**
  _Cohesion score 0.1021021021021021 - nodes in this community are weakly interconnected._
- **Should `Editor State & Input` be split into smaller, more focused modules?**
  _Cohesion score 0.0945945945945946 - nodes in this community are weakly interconnected._
- **Should `Implementation Plan` be split into smaller, more focused modules?**
  _Cohesion score 0.06890756302521009 - nodes in this community are weakly interconnected._
- **Should `TUI Render Pipeline` be split into smaller, more focused modules?**
  _Cohesion score 0.12121212121212122 - nodes in this community are weakly interconnected._