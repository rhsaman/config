---
name: vision-workflow
description: Route all image analysis requests to the vision subagent
---
## Workflow

When the user references an image and asks for analysis:

1. **Path provided explicitly?** Use it directly.
2. **Only filename given?** Search with `mdfind`. If not found on Desktop/Downloads, search in `/var/folders/.../TemporaryItems/` with `find` using `/private/var/folders/.../T/TemporaryItems/`.
3. **macOS temp path found but unreadable?** macOS SIP blocks CLI access to `TemporaryItems/`. Ask the user to drag the file into the terminal and paste the full path, or save it to Desktop first.
4. **Not found anywhere?** Ask the user to save and provide the path.
5. Once the path is confirmed, call `task` with `subagent_type: "vision"` and include the full path in the prompt.
6. Return the vision agent's analysis.

> The main model cannot read images — the vision subagent must always be used.
