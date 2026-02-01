# Context Bus

**Seamless multi-model orchestration for AI coding agents.**

Switch between Claude, Codex, Gemini, and local models without losing context. Context Bus provides shared memory files that all models read, plus automatic switching when you hit usage limits.

[![PyPI](https://img.shields.io/pypi/v/context-bus)](https://pypi.org/project/context-bus/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)]()

---

## The Problem

You're deep in a coding session with Claude Opus. You hit the usage limit. Now you need to switch to Codex or Gemini, but:

- ❌ The new model doesn't know what you were working on
- ❌ You have to re-explain the project context
- ❌ Previous decisions and constraints are lost
- ❌ You waste time catching up instead of coding

## The Solution

Context Bus solves this with two capabilities:

### 1. Shared Context Layer

All models read from the same files:

```
your-project/
├── AGENTS.md      ← Project context, constraints, current task
├── MEMORY.md      ← Long-term memory, decisions, preferences
└── ...
```

**Edit once → every model sees the same context.** No re-explaining.

### 2. Automatic Model Switching

When you approach usage limits:

```
Opus at 95% → Auto-generate context summary
            → Switch to Codex
            → Preserve full context in handoff.json
            → Notify you on Telegram/Discord/Slack
            → Continue working seamlessly

Limits reset → Auto-switch back to Opus
```

---

## Installation

### Via pip (Recommended)

```bash
pip install context-bus
context-bus init
```

### Via curl

```bash
curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/install.sh | bash
```

### Via your AI agent

Just ask:
```
"Install Context Bus for automatic model switching"
```

---

## Quick Start

### 1. Initialize in your project

```bash
cd your-project
context-bus init
```

This creates:
- `AGENTS.md` — Shared project context
- `MEMORY.md` — Long-term memory
- `~/.context-bus/` — Scripts and state
- `~/.config/context-bus/config.yaml` — Configuration

### 2. Configure notifications (optional)

Edit `~/.config/context-bus/config.yaml`:

```yaml
notifications:
  enabled: true
  channel: telegram
  telegram:
    chat_id: "YOUR_CHAT_ID"
```

### 3. Add to your agent's instructions

For OpenClaw/Clawdbot, add to `HEARTBEAT.md`:

```markdown
## Context Bus Auto-Switch

Check usage via `session_status`. If >= 95%:
1. Run `~/.context-bus/context-handoff.sh opus codex auto_threshold`
2. Notify: "🔄 Auto-switched to Codex (Opus at X%)"

If usage < 50% AND on codex AND idle:
1. Run `~/.context-bus/model-router.sh --reset`  
2. Notify: "🔄 Switched back to Opus"
```

---

## How It Works

### Shared Context Files

**AGENTS.md** — Read by every model at session start:
```markdown
# AGENTS.md

## Project Context
Building a task management API with PostgreSQL.

## Current Task
Implementing user authentication with JWT.

## Key Constraints
- Use TypeScript
- Write tests for all endpoints
- Follow existing code patterns

## Decisions Made
- JWT tokens expire in 1 hour
- Refresh tokens stored in httpOnly cookies
```

**MEMORY.md** — Long-term memory across sessions:
```markdown
# MEMORY.md

## Lessons Learned
- Always run migrations before testing
- User prefers concise code comments

## Project History
### 2026-02-01
- Added OAuth flow
- Decided on JWT over sessions
```

### Handoff Protocol

When switching models, Context Bus generates:

```
~/.context-bus/
├── handoff.json         ← Structured state (machine-readable)
├── rolling-summary.md   ← Human-readable summary (<400 tokens)
└── handoff-prompt.md    ← Ready-to-paste prompt for new model
```

**handoff.json example:**
```json
{
  "version": 1,
  "timestamp": "2026-02-01T14:00:00Z",
  "task": {
    "description": "Implementing OAuth authentication",
    "status": "in_progress"
  },
  "model": {
    "current": "codex",
    "previous": "opus",
    "switch_reason": "usage_threshold",
    "usage_percent": 96
  },
  "context_refs": ["AGENTS.md", "src/auth/oauth.ts"],
  "next_steps": ["Add token refresh", "Write tests"]
}
```

---

## CLI Commands

```bash
# Initialize in a workspace
context-bus init

# Check current status
context-bus status

# Manual model switching
context-bus switch codex
context-bus switch opus

# View configuration
context-bus config --show
context-bus config --edit
```

---

## Configuration

Full config at `~/.config/context-bus/config.yaml`:

```yaml
# Models
models:
  primary: opus
  secondary: codex
  tertiary: gemini

# When to switch
thresholds:
  switch_to_secondary: 95    # Switch at 95% usage
  switch_back: 50            # Switch back when usage drops

# Notifications
notifications:
  enabled: true
  channel: telegram          # telegram | discord | slack | none
  telegram:
    chat_id: ""
  discord:
    webhook_url: ""
  slack:
    webhook_url: ""

# Safety
safety:
  check_tasks_before_return: true   # Don't switch if task in progress
  check_subagents: true             # Don't switch if sub-agents active
```

---

## Supported Models

| Model | CLI | Notes |
|-------|-----|-------|
| Claude Opus 4.5 | `claude` | Primary, usage tracked |
| OpenAI Codex | `codex` | Secondary fallback |
| Gemini CLI | `gemini` | Tertiary option |
| Local (Ollama) | `ollama` | Background/offline |

---

## Safety Features

Context Bus includes safeguards:

| Check | What It Does |
|-------|--------------|
| **Task status** | Won't switch back if task is `in_progress` |
| **Sub-agents** | Won't switch if spawned sessions are active |
| **Cooldown** | Minimum 5 minutes between switches |
| **Safe augment** | Never overwrites existing AGENTS.md or MEMORY.md |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR PROJECT                           │
│                                                             │
│   AGENTS.md ←──────────────────────────────────────────┐   │
│   MEMORY.md ←──────────────────────────────────────────┤   │
│                                                         │   │
└─────────────────────────────────────────────────────────┼───┘
                                                          │
┌─────────────────────────────────────────────────────────┼───┐
│                     CONTEXT BUS                         │   │
│                                                         ▼   │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Monitor   │ →  │   Handoff   │ →  │   Switch    │     │
│  │ Usage check │    │ Gen summary │    │  + Notify   │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
│  State: ~/.context-bus/handoff.json                        │
│  Config: ~/.config/context-bus/config.yaml                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         MODELS                              │
│                                                             │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐   ┌─────────┐  │
│   │  Opus   │ ←→ │  Codex  │ ←→ │ Gemini  │ ←→│  Local  │  │
│   │ Primary │    │Secondary│    │Tertiary │   │ Ollama  │  │
│   └─────────┘    └─────────┘    └─────────┘   └─────────┘  │
│                                                             │
│   All models read: AGENTS.md, MEMORY.md, handoff.json      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Integrations

### OpenClaw / Clawdbot

Context Bus integrates seamlessly with OpenClaw agents:

1. Install: `pip install context-bus && context-bus init`
2. Add rules to `HEARTBEAT.md` (see [integrations/openclaw/](integrations/openclaw/))
3. Agent auto-switches and notifies during heartbeats

### Claude Code / Cursor / Other Agents

Add to your agent's system prompt:
```
Before starting work, read AGENTS.md and MEMORY.md for context.
After significant work, update these files.
If switching models, read ~/.context-bus/handoff.json for state.
```

---

## Troubleshooting

### "context-bus: command not found"

Add to PATH or use full path:
```bash
~/.context-bus/model-router.sh
```

### "Usage unknown"

Run `/status` in your agent, then update:
```bash
~/.context-bus/update-usage.sh 78
```

### "Notifications not sending"

Check config:
```bash
context-bus config --show
# Verify telegram.chat_id is set
```

---

## Uninstall

```bash
pip uninstall context-bus
rm -rf ~/.context-bus ~/.config/context-bus
```

Or:
```bash
curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/uninstall.sh | bash
```

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Links

- **PyPI:** https://pypi.org/project/context-bus/
- **GitHub:** https://github.com/rajathkm/context-bus
- **Issues:** https://github.com/rajathkm/context-bus/issues
