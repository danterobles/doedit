---
name: run
description: Build and run the doedit TUI app in the terminal for visual verification. Use after making changes to confirm the app compiles and renders correctly.
disable-model-invocation: false
---

Run the following command from the project root and report the output:

```
swift run
```

If the build fails, show the compiler errors in full — do not truncate.

If it succeeds and the app launches, describe what is rendered in the terminal. If the app requires a Ctrl+C to exit, note that.

For release builds or testing the final binary:
```
swift build -c release
.build/release/doedit
```
