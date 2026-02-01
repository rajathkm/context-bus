# OpenClaw Integration

Context Bus is designed primarily for OpenClaw (Clawdbot) users. This document explains how the integration works.

## How It Works

### 1. HEARTBEAT.md Rules

When you run `context-bus init`, it adds rules to your `HEARTBEAT.md`:

```markdown
## Context Bus - Usage Monitor

**On every heartbeat, check model usage:**
1. Run `session_status` to get current usage percentage
2. Update handoff.json: `~/.context-bus/update-usage.sh <percentage>`
3. Read current model from `~/.context-bus/handoff.json`

**Auto-switch rules:**
- If usage >= 95% AND model is "opus": switch to Codex, notify
- If usage < 50% AND model is "codex" AND idle: switch back to Opus
```

### 2. Heartbeat Execution

Your Clawdbot reads `HEARTBEAT.md` during each heartbeat cycle (default: every 30 minutes). When it sees the Context Bus rules, it:

1. Runs `session_status` to check current usage
2. Calls `~/.context-bus/update-usage.sh <percentage>` to update state
3. Checks if threshold is reached
4. If switching is needed, runs the handoff script and notifies you

### 3. Background Monitor

A background process (launchd on macOS, cron on Linux) runs every 10 minutes to:

1. Read `~/.context-bus/handoff.json`
2. Check if usage threshold is reached
3. Trigger model switch if needed
4. Send notification via configured channel

This provides a safety net in case heartbeats are delayed.

## Files

### Added to Your Workspace

| File | Purpose | Created By |
|------|---------|------------|
| `AGENTS.md` | Shared project context | `context-bus init` (if not exists) |
| `MEMORY.md` | Long-term memory | `context-bus init` (if not exists) |
| `HEARTBEAT.md` | + Context Bus rules | `context-bus init` (augmented) |

### System Files

| File | Purpose |
|------|---------|
| `~/.context-bus/handoff.json` | Current state (model, usage, task) |
| `~/.context-bus/usage-monitor.sh` | Background monitor script |
| `~/.context-bus/update-usage.sh` | Update usage script |
| `~/.config/context-bus/config.yaml` | Configuration |

## Notifications

Context Bus sends notifications through your existing OpenClaw channels:

```
🔄 [Context Bus] Opus → Codex
   Usage: 96%
   Context preserved ✓
```

Configure in `~/.config/context-bus/config.yaml`:

```yaml
notifications:
  channel: telegram
  telegram:
    chat_id: "YOUR_CHAT_ID"
```

## Manual Commands

Your Clawdbot can also respond to manual commands:

| Say | What Happens |
|-----|--------------|
| "Check usage" | Shows current model and usage % |
| "Switch to Codex" | Manual switch to Codex |
| "Switch to Opus" | Manual switch back to Opus |
| "Model status" | Shows handoff.json state |

## Troubleshooting

### Heartbeat not checking usage

Verify HEARTBEAT.md has the rules:
```bash
grep "Context Bus" HEARTBEAT.md
```

If missing, run `context-bus init` again.

### Usage not updating

Check handoff.json:
```bash
cat ~/.context-bus/handoff.json | jq .model
```

If `usage_percent` is stale, the heartbeat isn't running the update script.

### Monitor not running

```bash
# macOS
launchctl list | grep contextbus

# Check logs
tail -20 ~/.context-bus/monitor.log
```
