# Context Bus v3 — Final Architecture Plan

## Overview

Context Bus enables seamless model switching (Opus → Codex → Gemini) for AI agents without losing context. Agent-scoped, not project-scoped.

## File Structure

```
AGENT_WORKSPACE/                    # e.g., ~/clawd for Clawdbot
├── AGENTS.md                       # Agent identity
├── MEMORY.md                       # Long-term memory
├── HEARTBEAT.md                    # Heartbeat + Context Bus rules
└── .context-bus/
    ├── handoff.json                # Versioned state with expiry
    ├── rolling-summary.md          # Structured summary (YAML frontmatter)
    ├── history.jsonl               # Event log (rotated at 10MB)
    └── .lock                       # Concurrency lock

~/.config/context-bus/config.yaml   # Global config
```

## Handoff.json Schema (v3)

```json
{
  "schema_version": 3,
  "sequence": 47,
  "timestamp": "2026-02-01T15:15:00+05:30",
  "handoff_ready": true,
  "handoff_expires": "2026-02-01T15:20:00+05:30",
  "checksum": "sha256:abc123...",
  "author": "opus",
  
  "model": {
    "current": "opus",
    "usage_percent": 87,
    "history": [
      {"model": "opus", "from": "2026-02-01T10:00:00Z", "until": null}
    ]
  },
  
  "task": {
    "description": "Building Context Bus package",
    "status": "in_progress",
    "project": "~/Downloads/context-bus"
  },
  
  "context": {
    "recent_actions": ["action1", "action2", "action3"],
    "decisions": ["decision1", "decision2"],
    "next_steps": ["step1", "step2"],
    "blockers": []
  },
  
  "files_touched": ["file1.ts", "file2.md"]
}
```

## Key Fixes in v3

### 1. Handoff Expiry (No Stale Data)
- `handoff_expires` = timestamp + 5 minutes
- Monitor rejects handoff if expired
- Forces fresh update before switch

### 2. Explicit Switch-Back Workflow
```
If model == "codex" AND usage < 50% AND task.status == "idle":
    Switch back to Opus
    Notify user
```

### 3. Adaptive Monitor Interval
- Default: 5 minutes
- At usage > 70%: 2 minutes
- Prevents missing the 95% threshold

### 4. Merge-Based Writes (No Data Loss)
```bash
# Read existing → Merge new → Write
existing=$(cat handoff.json)
merged=$(echo "$existing" | jq ". * $new_content")
echo "$merged" > handoff.json
```

### 5. Correct Checksum Flow
```bash
# 1. Write final content to temp
# 2. Compute checksum of temp
# 3. Embed checksum in file
# 4. Atomic rename (no further modifications)
```

### 6. Model History (Multi-Switch Support)
```json
"history": [
  {"model": "opus", "from": "...", "until": "...", "reason": "threshold"},
  {"model": "codex", "from": "...", "until": null}
]
```

### 7. Offline Detection (Abort Stale Switch)
```bash
age_minutes = (now - last_timestamp) / 60
if age_minutes > 30:
    notify "Agent offline, aborting switch"
    exit
```

### 8. Log Rotation
```bash
if size(history.jsonl) > 10MB:
    mv history.jsonl history.YYYYMMDD.jsonl.gz
```

### 9. Cross-Platform Locking
- POSIX: flock
- Windows: msvcrt.locking
- NFS: Advisory locks via Python

## Heartbeat Rules

```markdown
## Context Bus — On Session Start

1. Read .context-bus/handoff.json
2. If model switched (model.history has entries):
   - Read rolling-summary.md
   - Acknowledge previous work
3. Continue

## Context Bus — On Every Heartbeat

1. Run session_status → get usage %
2. Update .context-bus/handoff.json:
   - timestamp = now
   - handoff_expires = now + 5 min
   - model.usage_percent
   - task, context.recent_actions, context.next_steps
   - handoff_ready = true
3. If usage >= 80%: Generate rolling-summary.md
4. Log to history.jsonl

## Context Bus — Switch-Back

If model == "codex" AND usage < 50% AND task.status == "idle":
1. Update handoff.json: model.current = "opus"
2. Add to model.history
3. Notify: "🔄 Switched back to Opus"
```

## Monitor Logic

```python
def check_and_switch():
    handoff = read_json(".context-bus/handoff.json")
    config = read_yaml("~/.config/context-bus/config.yaml")
    
    usage = handoff["model"]["usage_percent"]
    model = handoff["model"]["current"]
    expires = parse_time(handoff["handoff_expires"])
    timestamp = parse_time(handoff["timestamp"])
    
    # Check if agent is offline
    age_minutes = (now() - timestamp).minutes
    if age_minutes > 30:
        notify("⚠️ Agent offline for {age_minutes}m — not switching")
        return
    
    # Check if handoff is valid
    handoff_valid = (
        handoff["handoff_ready"] == True and
        expires > now() and
        verify_checksum(handoff)
    )
    
    # Switch to secondary
    if model == "opus" and usage >= config["thresholds"]["switch_to_secondary"]:
        if handoff_valid:
            switch_model("opus", "codex", "auto_threshold")
            notify("🔄 Switched Opus → Codex ({usage}%)")
        else:
            wait(60)  # Wait for heartbeat to update
            if still_not_valid():
                switch_model("opus", "codex", "incomplete_handoff")
                notify("⚠️ Switched with incomplete handoff")
    
    # Switch back to primary
    if model == "codex" and usage < config["thresholds"]["switch_back"]:
        task_status = handoff["task"]["status"]
        if task_status in ["idle", "completed"]:
            switch_model("codex", "opus", "limits_reset")
            notify("🔄 Switched back to Opus (limits reset)")
```

## Installation

```bash
pip install context-bus
context-bus init
```

Installer:
1. Detects agent workspace (has AGENTS.md + HEARTBEAT.md)
2. Creates .context-bus/ with initialized handoff.json
3. Augments HEARTBEAT.md (doesn't overwrite)
4. Sets up background monitor (launchd/cron)
5. Creates config.yaml with defaults

## Guarantees

| Guarantee | Implementation |
|-----------|----------------|
| No stale handoff | 5-min expiry + timestamp validation |
| No data loss | Merge-based writes + atomic rename |
| No race conditions | File locking (cross-platform) |
| No missed switches | 5-min monitor (2-min at >70%) |
| No stuck on fallback | Explicit switch-back at <50% |
| No offline mistakes | Abort if agent inactive >30min |
| No unbounded logs | Rotate at 10MB |
