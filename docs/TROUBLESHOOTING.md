# Troubleshooting

## Auto-Switch Didn't Trigger

### Problem
You hit 100% usage but Context Bus didn't auto-switch to the secondary model.

### Causes & Fixes

**1. Usage wasn't being tracked**

The handoff.json needs to be updated with current usage. Check:
```bash
cat ~/.context-bus/handoff.json | grep usage_percent
```

If it shows old/stale data, the heartbeat check isn't running. Fix:
- Ensure heartbeat is configured (OpenClaw: 30 min interval)
- Heartbeat must run `session_status` and update usage

**2. Heartbeat interval too long**

Default heartbeat is 30 minutes. If you burn through 15% usage in 20 minutes, you'll hit 100% before the next check.

Fix: Reduce heartbeat interval or add a cron job:
```bash
# Check every 10 minutes
*/10 * * * * ~/.context-bus/check-usage.sh
```

**3. Agent was too busy to check**

If you're in a rapid conversation, heartbeats may be skipped.

Fix: Add a "check usage every N messages" rule to your agent.

**4. Threshold set too high**

If threshold is 98%, there's very little buffer.

Fix: Lower threshold in config:
```yaml
thresholds:
  switch_to_secondary: 90  # More buffer
```

---

## Switch Happened But Context Was Lost

### Problem
Model switched but the new model doesn't have context.

### Fixes

**1. Handoff files not generated**

Check if files exist:
```bash
ls -la ~/.context-bus/
# Should see: handoff.json, rolling-summary.md, handoff-prompt.md
```

If missing, run manually:
```bash
~/.context-bus/context-handoff.sh opus codex manual
```

**2. New model not reading handoff files**

Ensure your agent's instructions include:
```
Read ~/.context-bus/handoff.json and rolling-summary.md for context.
```

---

## Notifications Not Sending

### Telegram

1. Check chat ID is set:
```bash
grep chat_id ~/.config/context-bus/config.yaml
```

2. Get your chat ID from [@userinfobot](https://t.me/userinfobot)

3. For OpenClaw users: notifications go through the main session, not a separate bot

### Discord

1. Check webhook URL is valid
2. Test webhook manually:
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"content": "Test from Context Bus"}' \
  "YOUR_WEBHOOK_URL"
```

---

## "command not found" Errors

### Fix 1: Use full path
```bash
~/.context-bus/model-router.sh
```

### Fix 2: Add to PATH
```bash
echo 'export PATH="$PATH:$HOME/.context-bus"' >> ~/.zshrc
source ~/.zshrc
```

---

## Rapid Toggling Between Models

### Problem
Context Bus keeps switching back and forth.

### Cause
The `switch_back` threshold is too close to current usage, or usage data is fluctuating.

### Fix
1. Increase minimum interval:
```yaml
thresholds:
  min_switch_interval: 600  # 10 minutes
```

2. Lower switch-back threshold:
```yaml
thresholds:
  switch_back: 30  # Only return at 30%
```

---

## handoff.json Is Corrupted

### Fix
Reset it:
```bash
cat > ~/.context-bus/handoff.json << 'EOF'
{
  "version": 1,
  "timestamp": null,
  "task": {"id": null, "description": null, "status": "idle"},
  "model": {"current": "opus", "previous": null, "usage_percent": null},
  "context_refs": ["AGENTS.md", "MEMORY.md"],
  "recent_actions": [],
  "next_steps": []
}
EOF
```

---

## Need More Help?

- Open an issue: https://github.com/rajathkm/context-bus/issues
- Include: OS, Python version, config (redact secrets), error messages
