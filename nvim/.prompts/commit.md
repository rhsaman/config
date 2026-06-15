---
name: Commit message
interaction: chat
description: Generate and apply a commit message
opts:
  alias: commit
  auto_submit: true
  adapter:
    name: lm_studio
    model: qwen2.5-coder-1.5b-instruct
tools:
  - run_command
---

## user

You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message, then run `git commit` with it.

```diff
${commit.diff}
```
