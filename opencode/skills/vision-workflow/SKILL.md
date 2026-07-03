---
name: vision-workflow
description: Route all image analysis requests to lmstudio qwen3.5-4b VL model via local API
---
## Workflow

When the user references an image and asks for analysis:

1. **Path provided explicitly?** Use it directly.
2. **Only filename given?** Search with `mdfind`. If not found on Desktop/Downloads, search in `/var/folders/.../TemporaryItems/` with `find` using `/private/var/folders/.../T/TemporaryItems/`.
3. **macOS temp path found but unreadable?** macOS SIP blocks CLI access to `TemporaryItems/`. Ask the user to drag the file into the terminal and paste the full path, or save it to Desktop first.
4. **Not found anywhere?** Ask the user to save and provide the path.
5. Once the path is confirmed, call LM Studio API directly with qwen3.5-4b model:
   - Convert image to small JPEG (max 400px) using `magick convert`
   - Base64 encode and send to `http://localhost:1234/v1/chat/completions`
   - Model: `qwen3.5-4b`, max_tokens: 300, timeout: 120s
   - Use multimodal format with `image_url` containing `data:image/jpeg;base64,...`
6. Return the vision analysis result.

> The main model cannot read images — always use LM Studio qwen3.5-4b for vision.
