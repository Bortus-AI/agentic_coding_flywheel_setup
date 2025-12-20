# Your Agent Commands

**Goal:** Login to your coding agents and understand the shortcuts.

---

## The Three Agents

You have three powerful coding agents installed:

| Agent | Command | Alias | Company |
|-------|---------|-------|---------|
| Claude Code | `claude` | `cc` | Anthropic |
| Codex CLI | `codex` | `cod` | OpenAI |
| Gemini CLI | `gemini` | `gmi` | Google |

---

## What The Aliases Do

The aliases are configured for **maximum power** (vibe mode):

### `cc` (Claude Code)
```bash
NODE_OPTIONS="--max-old-space-size=32768" \
  ENABLE_BACKGROUND_TASKS=1 \
  claude --dangerously-skip-permissions
```
- Extra memory for large projects
- Background task support
- No permission prompts

### `cod` (Codex CLI)
```bash
codex --dangerously-bypass-approvals-and-sandbox \
  -m gpt-5.2-codex \
  -c model_reasoning_effort="xhigh" \
  -c model_reasoning_summary_format=experimental \
  --enable web_search_request
```
- Bypass safety prompts
- High reasoning effort
- Web search enabled

### `gmi` (Gemini CLI)
```bash
gemini --yolo --model gemini-3-pro-preview
```
- YOLO mode (no confirmations)
- Latest preview model

---

## First Login

Each agent needs to be authenticated once:

### Claude Code
```bash
claude auth login
```
Follow the browser link to authenticate with your Anthropic account.

### Codex CLI
```bash
codex auth
```
Follow the prompts to authenticate with your OpenAI account.

### Gemini CLI
```bash
gemini auth
```
Follow the prompts to authenticate with your Google account.

---

## Backup Your Credentials!

After logging in, **immediately** back up your credentials:

```bash
caam backup claude my-main-account
caam backup codex my-main-account
caam backup gemini my-main-account
```

Now you can switch accounts later with:
```bash
caam activate claude my-other-account
```

This is incredibly useful when you hit rate limits!

---

## Test Your Agents

Try each one:

```bash
cc "Hello! Please confirm you're working."
```

```bash
cod "Hello! Please confirm you're working."
```

```bash
gmi "Hello! Please confirm you're working."
```

---

## Quick Tips

1. **Start simple** - Let agents do small tasks first
2. **Be specific** - Clear instructions get better results
3. **Check the output** - Agents can make mistakes
4. **Use multiple agents** - Different agents have different strengths

---

## Next

Now let's learn NTM - the tool that orchestrates all these agents:

```bash
onboard lesson 5
```
