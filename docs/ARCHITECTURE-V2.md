# Context Bus v2 — Architecture Plan

## Overview

Context Bus enables seamless model switching (Opus → Codex → Gemini) for AI agents without losing context. When an agent hits usage limits, it automatically switches to a fallback model with full context preserved.

## Core Concept: Agent-Scoped Switching

Context Bus operates at the **agent level**, not project level:

```
AGENT (e.g., Clawdbot)
    │
    ├── Works on Project A
    ├── Works on Project B  
    ├── Works on Project C
    │
    └── ALL share one model
        │
        └── When Opus hits 95% → ENTIRE AGENT switches to Codex
            │
            └── Handoff = Agent's current state (all projects)
```

## File Structure

```
AGENT_WORKSPACE/                    # e.g., ~/clawd for Clawdbot
├── AGENTS.md                       # Agent identity (existing)
├── MEMORY.md                       # Long-term memory (existing)
├── HEARTBEAT.md                    # Heartbeat rules + Context Bus rules
│
└── .context-bus/                   # Context Bus state (NEW)
    ├── handoff.json                # Versioned agent state
    ├── rolling-summary.md          # Structured session summary
    ├── history.jsonl               # Append-only event log
    └── .lock                       # Concurrency lock

~/.config/context-bus/
└── config.yaml                     # Global config (thresholds, notifications)
```

## Handoff.json Schema (v2)

```json
{
  "schema_version": 2,
  "sequence": 47,
  "timestamp": "2026-02-01T15:15:00+05:30",
  "checksum": "sha256:abc123...",
  "author": "opus",
  "handoff_ready": true,
  
  "model": {
    "current": "opus",
    "previous": null,
    "usage_percent": 87,
    "switch_reason": null
  },
  
  "task": {
    "description": "Building Context Bus package",
    "status": "in_progress",
    "project": "~/Downloads/context-bus"
  },
  
  "context": {
    "recent_actions": [
      "Created ARCHITECTURE-V2.md",
      "Updated installer script",
      "Pushed to GitHub"
    ],
    "decisions": [
      "Agent-scoped not project-scoped",
      "Workspace-local .context-bus/",
      "Atomic writes for integrity"
    ],
    "next_steps": [
      "Get Codex feedback",
      "Implement revised plan",
      "Update PyPI package"
    ],
    "blockers": []
  },
  
  "files_touched": [
    "docs/ARCHITECTURE-V2.md",
    "install.sh",
    "scripts/usage-monitor.sh"
  ]
}
```

## Rolling-Summary.md Format

```markdown
---
schema_version: 2
generated: 2026-02-01T15:15:00+05:30
author: opus
token_count: 350
---

# Agent Handoff Summary

## TL;DR
Building Context Bus v2 — agent-scoped model switching with full context preservation.

## Current Focus
Finalizing architecture based on Codex critique. Key change: workspace-local .context-bus/ instead of global ~/.context-bus/.

## Recent Progress
- Created comprehensive architecture doc
- Updated installer for workspace detection
- Added atomic writes and versioning

## Key Decisions Made
1. Agent-scoped (not per-project) — one agent = one handoff
2. Workspace-local storage — .context-bus/ in agent's home
3. Forced final heartbeat before switch — no stale handoffs

## Immediate Next Steps
1. Get Codex to review this plan
2. Implement changes
3. Update GitHub + PyPI

## Open Items
- None currently
```

## Heartbeat Flow

### On Session Start
```
1. Read .context-bus/handoff.json
2. Check if model.previous exists (indicates switch happened)
3. If switch happened:
   - Read rolling-summary.md
   - Acknowledge: "Continuing from [previous model]'s work on [task]"
4. Continue working
```

### On Every Heartbeat
```
1. Run session_status → get usage %
2. Update .context-bus/handoff.json:
   - model.usage_percent
   - task.description, task.status
   - context.recent_actions (last 5)
   - context.next_steps
   - timestamp
   - handoff_ready = true
3. If usage >= 80%:
   - Generate .context-bus/rolling-summary.md (proactive)
4. Log event to history.jsonl
```

### Pre-Switch (Monitor Triggered)
```
Monitor detects usage >= 95%
    ↓
Check handoff_ready in handoff.json
    ↓
If NOT ready:
    - Wait up to 60 seconds
    - Trigger forced heartbeat
    ↓
Validate handoff:
    - Timestamp < 5 min old
    - Checksum matches
    - handoff_ready = true
    ↓
If valid: Execute switch
If invalid: Switch anyway + warn user
    ↓
Update handoff.json: model.current = "codex", model.previous = "opus"
    ↓
Notify user: "🔄 Switched Opus → Codex (96%). Context preserved."
```

## Atomic Write Pattern

```bash
write_handoff() {
    local content="$1"
    local target="$WORKSPACE/.context-bus/handoff.json"
    local lockfile="$WORKSPACE/.context-bus/.lock"
    
    # Acquire lock
    exec 200>"$lockfile"
    flock -w 5 200 || { echo "Lock timeout"; return 1; }
    
    # Write to temp
    local tmp=$(mktemp)
    echo "$content" > "$tmp"
    
    # Compute checksum
    local checksum=$(sha256sum "$tmp" | cut -d' ' -f1)
    
    # Add checksum and increment sequence
    local seq=$(jq -r '.sequence // 0' "$target" 2>/dev/null || echo 0)
    seq=$((seq + 1))
    
    jq ".checksum = \"sha256:$checksum\" | .sequence = $seq" "$tmp" > "${tmp}.final"
    
    # Atomic rename
    mv "${tmp}.final" "$target"
    rm -f "$tmp"
    
    # Release lock
    flock -u 200
}
```

## Background Monitor

Runs every 10 minutes (launchd on macOS, cron on Linux):

```bash
#!/bin/bash
# usage-monitor.sh

WORKSPACE="${CONTEXT_BUS_WORKSPACE:-$HOME/clawd}"
HANDOFF="$WORKSPACE/.context-bus/handoff.json"
CONFIG="$HOME/.config/context-bus/config.yaml"

# Read current state
usage=$(jq -r '.model.usage_percent // 0' "$HANDOFF")
model=$(jq -r '.model.current // "opus"' "$HANDOFF")
ready=$(jq -r '.handoff_ready // false' "$HANDOFF")

# Read thresholds from config
threshold=$(grep 'switch_to_secondary' "$CONFIG" | awk '{print $2}')

# Check if switch needed
if [[ "$model" == "opus" ]] && [[ "$usage" -ge "$threshold" ]]; then
    if [[ "$ready" == "true" ]]; then
        # Execute switch
        switch_model "opus" "codex" "auto_threshold"
    else
        # Wait and retry
        sleep 30
        ready=$(jq -r '.handoff_ready' "$HANDOFF")
        if [[ "$ready" == "true" ]]; then
            switch_model "opus" "codex" "auto_threshold"
        else
            switch_model "opus" "codex" "auto_threshold_incomplete"
            notify "⚠️ Switched with incomplete handoff"
        fi
    fi
fi
```

## Installation Flow

```bash
context-bus init
    ↓
Detect workspace type:
    - Has AGENTS.md + HEARTBEAT.md? → OpenClaw agent workspace
    - Otherwise? → Regular project
    ↓
Create .context-bus/ in detected workspace
    ↓
Create handoff.json (initialized)
    ↓
Augment HEARTBEAT.md (if exists, add Context Bus section)
    ↓
Create HEARTBEAT.md (if not exists, with Context Bus rules)
    ↓
Setup background monitor (launchd/cron)
    ↓
Done!
```

## Config (config.yaml)

```yaml
# ~/.config/context-bus/config.yaml

workspace: ~/clawd                # Agent workspace path

models:
  primary: opus
  secondary: codex
  tertiary: gemini

thresholds:
  switch_to_secondary: 95
  switch_back: 50
  proactive_summary: 80           # Generate summary at this %

safety:
  max_handoff_age_minutes: 5
  require_handoff_ready: true
  retry_on_incomplete: true
  max_wait_seconds: 60

notifications:
  enabled: true
  channel: telegram
  telegram:
    chat_id: ""
```

## Summary

| Component | Location | Purpose |
|-----------|----------|---------|
| handoff.json | WORKSPACE/.context-bus/ | Versioned agent state |
| rolling-summary.md | WORKSPACE/.context-bus/ | Human-readable summary |
| history.jsonl | WORKSPACE/.context-bus/ | Event audit log |
| config.yaml | ~/.config/context-bus/ | User configuration |
| HEARTBEAT.md | WORKSPACE/ | Agent heartbeat rules |

| Guarantee | How |
|-----------|-----|
| No data loss | Atomic writes + checksums |
| No stale handoff | Timestamp validation + forced final heartbeat |
| No race conditions | File locking |
| No missed switches | Background monitor every 10 min |
