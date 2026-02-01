# Context Bus - HEARTBEAT.md Rules

Add this section to your `HEARTBEAT.md` for automatic model switching.

---

## Auto-Switch: Context Bus Model Management

### Check Usage & Auto-Switch
1. Run `session_status` to get current Opus usage percentage
2. Update handoff.json with current usage via: `~/.context-bus/update-usage.sh <percentage>`

### Auto-Switch Rules

**Switch TO Codex (at 95%):**
- If usage >= 95% AND current model is "opus"
- Run: `~/.context-bus/context-handoff.sh opus codex auto_threshold`
- Notify user: "🔄 Auto-switched to Codex (Opus at X%). Context preserved."

**Switch BACK to Opus (on reset):**
- If usage < 50% AND current model is "codex" AND previous check was >= 95%
- This indicates weekly/session reset occurred
- Run: `~/.context-bus/model-router.sh --reset`
- Notify user: "🔄 Auto-switched back to Opus (limits reset). Welcome back!"

### State Tracking
Check `.context-bus/handoff.json` for:
- `model.current`: "opus" or "codex"
- `model.usage_percent`: last known usage

### Safety Rules

**Before switching back to Opus, verify:**
1. No active tasks running (check `handoff.json` task.status != "in_progress")
2. No spawned sub-agents working (check `sessions_list` for active isolated sessions)
3. Conversation is idle (no pending user message being processed)

**If tasks are running:**
- Do NOT switch back
- Wait for next heartbeat
- Check again when idle

### Notifications

Always send a message when switching models:
- Format: "🔄 [Auto-switch] From X to Y. Reason: Z"
