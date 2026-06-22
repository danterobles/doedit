# Graph Report - .  (2026-06-22)

## Corpus Check
- 1 files · ~8,031 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 192 nodes · 302 edges · 13 communities (12 shown, 1 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_TUIkit Rendering Engine|TUIkit Rendering Engine]]
- [[_COMMUNITY_Focus & Navigation System|Focus & Navigation System]]
- [[_COMMUNITY_Editor Core & State|Editor Core & State]]
- [[_COMMUNITY_File Management & Sidebar|File Management & Sidebar]]
- [[_COMMUNITY_Search & Replace|Search & Replace]]
- [[_COMMUNITY_TUIkit Patch Management|TUIkit Patch Management]]
- [[_COMMUNITY_Input Handling|Input Handling]]
- [[_COMMUNITY_UI Prompts & Dialogs|UI Prompts & Dialogs]]
- [[_COMMUNITY_Status Bar & Context|Status Bar & Context]]
- [[_COMMUNITY_UndoRedo System|Undo/Redo System]]
- [[_COMMUNITY_App Entry & Layout|App Entry & Layout]]
- [[_COMMUNITY_Plan & Spec|Plan & Spec]]

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

## Communities (13 total, 1 thin omitted)

### Community 0 - "TUIkit Rendering Engine"
Cohesion: 0.10
Nodes (9): Character, Undo/Redo stack pattern, Snapshot, TextBuffer, Selection, Bool, Int, Range (+1 more)

### Community 1 - "Focus & Navigation System"
Cohesion: 0.09
Nodes (26): Comparable, Search and Replace feature, Viewport scroll / cursor visibility, Equatable, Hashable, Identifiable, FileEntry, MatchPosition (+18 more)

### Community 2 - "Editor Core & State"
Cohesion: 0.09
Nodes (24): FrameBuffer, Never, Phase 2 - Text Editing Engine, Renderable Protocol Pattern, TextBuffer [String] Array Design Rationale, Renderable, RenderContext, Clipboard (+16 more)

### Community 3 - "File Management & Sidebar"
Cohesion: 0.10
Nodes (21): IXON Raw Mode Rationale, NotificationService, Phase 0 - Scaffold and Discovery, Phase 1 - Sidebar, Phase 3 - Save and Quit, Phase 4 - Copy and Move Text, Phase 5 - Search and Go To Line, Phase 6 - Find and Replace (+13 more)

### Community 4 - "Search & Replace"
Cohesion: 0.20
Nodes (6): MatchPosition, EditorState, FileEntry, Int, String, TextBuffer

### Community 5 - "TUIkit Patch Management"
Cohesion: 0.31
Nodes (7): Focusable, EditorHandler, KeyEvent, Bool, Clipboard, String, TextBuffer

### Community 6 - "Input Handling"
Cohesion: 0.25
Nodes (6): App, Scene, settings.json (Claude hooks config), doeditApp, String, App protocol (TUIkit)

### Community 7 - "UI Prompts & Dialogs"
Cohesion: 0.36
Nodes (5): Row Truncation with Ellipsis, Sidebar Row Overflow Fix, TUIkit SPM Checkout (.build/checkouts/TUIkit), TUIkit _ListCore, apply-patches.sh script

### Community 8 - "Status Bar & Context"
Cohesion: 0.32
Nodes (6): LineEnding, FileService, Set, Bool, FileEntry, String

### Community 9 - "Undo/Redo System"
Cohesion: 0.40
Nodes (4): Binding, Bool, EditorState, GoToLinePrompt

### Community 10 - "App Entry & Layout"
Cohesion: 0.40
Nodes (4): Binding, Bool, EditorState, ReplacePrompt

## Knowledge Gaps
- **51 isolated node(s):** `Scene`, `String`, `KeyEvent`, `Bool`, `FileEntry` (+46 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `EditorHandler` connect `TUIkit Patch Management` to `Focus & Navigation System`, `Editor Core & State`?**
  _High betweenness centrality (0.461) - this node is a cross-community bridge._
- **Why does `TextBuffer` connect `TUIkit Rendering Engine` to `Focus & Navigation System`?**
  _High betweenness centrality (0.268) - this node is a cross-community bridge._
- **What connects `Scene`, `String`, `KeyEvent` to the rest of the system?**
  _53 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `TUIkit Rendering Engine` be split into smaller, more focused modules?**
  _Cohesion score 0.1021021021021021 - nodes in this community are weakly interconnected._
- **Should `Focus & Navigation System` be split into smaller, more focused modules?**
  _Cohesion score 0.0945945945945946 - nodes in this community are weakly interconnected._
- **Should `Editor Core & State` be split into smaller, more focused modules?**
  _Cohesion score 0.08994708994708994 - nodes in this community are weakly interconnected._
- **Should `File Management & Sidebar` be split into smaller, more focused modules?**
  _Cohesion score 0.09686609686609686 - nodes in this community are weakly interconnected._