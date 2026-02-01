# Configuration Guide

Context Bus is configured via `~/.config/context-bus/config.yaml`.

## Full Configuration Reference

```yaml
# =============================================================================
# MODEL CONFIGURATION
# =============================================================================
models:
  # Primary model - used until usage threshold is reached
  primary: opus
  
  # Secondary model - fallback when primary hits limits
  secondary: codex
  
  # Tertiary model - optional third fallback
  tertiary: gemini
  
  # Local model for background tasks (summarization, etc.)
  local:
    enabled: false
    provider: ollama
    model: llama3.1:8b
    endpoint: http://localhost:11434

# =============================================================================
# SWITCHING THRESHOLDS
# =============================================================================
thresholds:
  # Switch to secondary model when primary reaches this usage %
  switch_to_secondary: 95
  
  # Switch back to primary when usage drops below this %
  # (indicates a reset/new billing period)
  switch_back: 50
  
  # Minimum seconds between model switches (prevents rapid toggling)
  min_switch_interval: 300

# =============================================================================
# NOTIFICATIONS
# =============================================================================
notifications:
  # Master switch for all notifications
  enabled: true
  
  # Channel: telegram | discord | slack | none
  channel: telegram
  
  # Telegram configuration
  telegram:
    # Your Telegram chat ID (get from @userinfobot)
    chat_id: ""
    # Optional: Bot token (uses Clawdbot's if not set)
    bot_token: ""
  
  # Discord configuration  
  discord:
    # Webhook URL from your Discord server
    webhook_url: ""
  
  # Slack configuration
  slack:
    # Incoming webhook URL from Slack
    webhook_url: ""
  
  # Which events trigger notifications
  events:
    on_switch: true           # When switching models
    on_return: true           # When returning to primary
    on_error: true            # On errors
    on_threshold_warning: false  # At 80% usage (pre-warning)

# =============================================================================
# SAFETY RULES
# =============================================================================
safety:
  # Check handoff.json task.status before switching back
  check_tasks_before_return: true
  
  # Check for active sub-agents/spawned sessions
  check_subagents: true
  
  # If busy, wait and retry on next check
  wait_if_busy: true
  
  # Maximum heartbeat cycles to wait before alerting
  max_wait_heartbeats: 10

# =============================================================================
# PATHS
# =============================================================================
paths:
  # Where Context Bus stores state
  context_dir: ~/.context-bus
  
  # Files to include in handoff context
  workspace_files:
    - AGENTS.md
    - MEMORY.md
    - memory/*.md

# =============================================================================
# ADVANCED
# =============================================================================
advanced:
  # Rolling summary max tokens
  summary_max_tokens: 400
  
  # Use semantic search (qmd) for relevant context
  use_semantic_search: false
  semantic_search_top_k: 5
  
  # Local summarization via Ollama
  local_summarization: false
  summarization_model: llama3.1:8b
```

## Environment Variables

These override config file values:

| Variable | Purpose |
|----------|---------|
| `CONTEXT_BUS_CONFIG` | Custom config file path |
| `CONTEXT_BUS_DIR` | Custom state directory |
| `TELEGRAM_CHAT_ID` | Telegram notifications |
| `DISCORD_WEBHOOK` | Discord notifications |
| `SLACK_WEBHOOK` | Slack notifications |

## Examples

### Minimal Config (Telegram Only)

```yaml
models:
  primary: opus
  secondary: codex

notifications:
  enabled: true
  channel: telegram
  telegram:
    chat_id: "123456789"
```

### Full Multi-Model Setup

```yaml
models:
  primary: opus
  secondary: codex
  tertiary: gemini
  local:
    enabled: true
    model: llama3.1:8b

thresholds:
  switch_to_secondary: 90
  switch_back: 40

notifications:
  enabled: true
  channel: discord
  discord:
    webhook_url: "https://discord.com/api/webhooks/..."
```

### Aggressive Switching (Don't Wait)

```yaml
thresholds:
  switch_to_secondary: 80
  min_switch_interval: 60

safety:
  check_tasks_before_return: false
  wait_if_busy: false
```
