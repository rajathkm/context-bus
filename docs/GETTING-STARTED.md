# Getting Started with Context Bus

This guide walks you through setting up Context Bus for seamless multi-model switching.

## Prerequisites

- Python 3.8+
- At least one AI coding agent (Claude Code, Codex, Gemini CLI, etc.)
- Optional: Telegram/Discord/Slack for notifications

## Step 1: Install

```bash
pip install context-bus
```

## Step 2: Initialize in Your Project

```bash
cd your-project
context-bus init
```

This creates:

| File | Purpose |
|------|---------|
| `AGENTS.md` | Shared project context (all models read this) |
| `MEMORY.md` | Long-term memory across sessions |
| `~/.context-bus/` | Scripts and state files |
| `~/.config/context-bus/config.yaml` | Configuration |

## Step 3: Edit Your Context Files

### AGENTS.md

Add your project-specific context:

```markdown
# AGENTS.md

## Project Context
Building [your project description]

## Current Task
[What you're working on now]

## Key Constraints
- [Your coding standards]
- [Technology choices]
- [Things to avoid]

## Important Files
- README.md
- src/main.ts
- [other key files]
```

### MEMORY.md

Add things to remember long-term:

```markdown
# MEMORY.md

## User Preferences
- Prefers concise responses
- Uses TypeScript
- [Your preferences]

## Lessons Learned
- [Things you've learned during the project]
```

## Step 4: Configure Notifications (Optional)

Edit `~/.config/context-bus/config.yaml`:

```yaml
notifications:
  enabled: true
  channel: telegram
  telegram:
    chat_id: "YOUR_TELEGRAM_CHAT_ID"
```

To get your Telegram chat ID:
1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. It will reply with your chat ID

## Step 5: Set Up Auto-Switch (For OpenClaw Users)

Add to your `HEARTBEAT.md`:

```markdown
## Context Bus Auto-Switch

1. Run `session_status` to check usage
2. If usage >= 95%:
   - Run `~/.context-bus/context-handoff.sh opus codex auto_threshold`
   - Notify: "🔄 Auto-switched to Codex"
3. If usage < 50% AND on codex AND idle:
   - Run `~/.context-bus/model-router.sh --reset`
   - Notify: "🔄 Switched back to Opus"
```

## Step 6: Test It

```bash
# Check status
context-bus status

# Manual switch test
context-bus switch codex
context-bus switch opus
```

## Next Steps

- Read [Configuration Guide](CONFIGURATION.md) for all options
- See [Handoff Protocol](HANDOFF-PROTOCOL.md) for technical details
- Check [Troubleshooting](TROUBLESHOOTING.md) if you run into issues
