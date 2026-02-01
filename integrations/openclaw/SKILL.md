# Context Bus Skill

Automatic model switching for AI coding agents with full context preservation.

## Installation

```bash
# Install Context Bus
curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/install.sh | bash
```

Or ask your Clawdbot:
```
"Install Context Bus for automatic model switching"
```

## Usage

### Automatic (Recommended)

Add the contents of `HEARTBEAT_RULES.md` to your `HEARTBEAT.md`. Context Bus will:
1. Monitor Opus usage during heartbeats
2. Auto-switch to Codex at 95% usage
3. Notify you on Telegram
4. Auto-switch back when limits reset

### Manual Commands

Users can say:
- `check usage` - Show current Opus usage %
- `model status` - Show current model and state
- `switch to codex` - Manual switch to Codex
- `switch to opus` - Manual switch back to Opus

### Scripts

```bash
# Check model recommendation
~/.context-bus/model-router.sh

# Generate handoff for switching
~/.context-bus/context-handoff.sh opus codex reason

# Update usage percentage
~/.context-bus/update-usage.sh 78

# Refresh rolling summary
~/.context-bus/refresh-summary.sh
```

## Configuration

Edit `~/.config/context-bus/config.yaml`:

```yaml
models:
  primary: opus
  secondary: codex
  
thresholds:
  switch_to_secondary: 95
  switch_back: 50
  
notifications:
  channel: telegram
  telegram:
    chat_id: "YOUR_CHAT_ID"
```

## Files

| File | Purpose |
|------|---------|
| `~/.context-bus/handoff.json` | Current state |
| `~/.context-bus/rolling-summary.md` | Session summary |
| `~/.context-bus/handoff-prompt.md` | Ready for new model |
| `~/.config/context-bus/config.yaml` | Configuration |

## Integration with Agent

This skill integrates via HEARTBEAT.md. During each heartbeat:
1. Check usage via `session_status`
2. If threshold reached, run handoff
3. Notify user and switch models
4. Context is preserved in handoff files
