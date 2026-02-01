#!/bin/bash
# Context Bus v3 Installer
# Agent-scoped model switching with full context preservation

set -e

echo ""
echo "🚀 Context Bus v3 Installer"
echo "==========================="
echo ""

# Detect workspace
detect_workspace() {
    # Check current directory first
    if [[ -f "AGENTS.md" ]] || [[ -f "HEARTBEAT.md" ]]; then
        echo "$PWD"
        return
    fi
    
    # Check common locations
    for dir in "$HOME/clawd" "$HOME/.clawd" "$HOME/openclaw"; do
        if [[ -d "$dir" ]] && [[ -f "$dir/AGENTS.md" || -f "$dir/HEARTBEAT.md" ]]; then
            echo "$dir"
            return
        fi
    done
    
    # Default to current directory
    echo "$PWD"
}

WORKSPACE=$(detect_workspace)
CONTEXT_DIR="$WORKSPACE/.context-bus"
CONFIG_DIR="${HOME}/.config/context-bus"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📁 Detected workspace: $WORKSPACE"
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p "$CONTEXT_DIR"
mkdir -p "$CONFIG_DIR"
echo "   ✅ $CONTEXT_DIR"
echo "   ✅ $CONFIG_DIR"

# Copy scripts
echo ""
echo "📜 Installing scripts..."
if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
    cp "${SCRIPT_DIR}/scripts/handoff-utils.sh" "$CONTEXT_DIR/"
    cp "${SCRIPT_DIR}/scripts/usage-monitor-v3.sh" "$CONTEXT_DIR/usage-monitor.sh"
    chmod +x "$CONTEXT_DIR/"*.sh
    echo "   ✅ Scripts installed to $CONTEXT_DIR"
fi

# Initialize handoff.json
echo ""
echo "📝 Initializing handoff.json..."
if [[ ! -f "$CONTEXT_DIR/handoff.json" ]]; then
    source "$CONTEXT_DIR/handoff-utils.sh"
    CONTEXT_BUS_WORKSPACE="$WORKSPACE" init_handoff
    echo "   ✅ Created handoff.json (v3 schema)"
else
    echo "   ⏭️  handoff.json already exists"
fi

# Create config
echo ""
echo "⚙️  Setting up configuration..."
if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
    cat > "$CONFIG_DIR/config.yaml" << EOF
# Context Bus v3 Configuration

workspace: $WORKSPACE

models:
  primary: opus
  secondary: codex
  tertiary: gemini

thresholds:
  switch_to_secondary: 95
  switch_back: 50
  proactive_summary: 80

safety:
  max_handoff_age_seconds: 300
  require_handoff_ready: true
  offline_abort_minutes: 30

monitor:
  interval_normal: 300      # 5 minutes
  interval_high_usage: 120  # 2 minutes at >70%

notifications:
  enabled: true
  channel: telegram
  telegram:
    chat_id: ""
EOF
    echo "   ✅ Created config.yaml"
else
    echo "   ⏭️  config.yaml already exists"
fi

# Augment HEARTBEAT.md
echo ""
echo "🤖 Setting up HEARTBEAT.md..."

HEARTBEAT_RULES='
## Context Bus v3 — Usage Monitor & Handoff

### On Session Start

1. Read `.context-bus/handoff.json`
2. Check if `model.history` has entries (indicates previous switch)
3. If switch happened:
   - Read `.context-bus/rolling-summary.md`
   - Acknowledge: "Continuing from [previous model] work on [task]"

### On Every Heartbeat

1. Run `session_status` → get usage %
2. Update `.context-bus/handoff.json`:
   ```bash
   ~/.context-bus/handoff-utils.sh update '\''{"model": {"usage_percent": <X>}, "task": {"description": "...", "status": "..."}, "context": {"recent_actions": [...], "next_steps": [...]}}'\''
   ```
3. If usage >= 80%: Generate `.context-bus/rolling-summary.md`

### Switch-Back Rule

If model is "codex" AND usage < 50% AND task.status is "idle":
1. Update handoff.json: `model.current = "opus"`
2. Notify: "🔄 Switched back to Opus (limits reset)"

### State Files

- `.context-bus/handoff.json` — Current state (valid for 5 min)
- `.context-bus/rolling-summary.md` — Session summary
- `.context-bus/history.jsonl` — Event log
'

if [[ -f "$WORKSPACE/HEARTBEAT.md" ]]; then
    if ! grep -q "Context Bus v3" "$WORKSPACE/HEARTBEAT.md" 2>/dev/null; then
        # Remove old Context Bus section if present
        if grep -q "Context Bus" "$WORKSPACE/HEARTBEAT.md" 2>/dev/null; then
            # Create backup
            cp "$WORKSPACE/HEARTBEAT.md" "$WORKSPACE/HEARTBEAT.md.bak"
            # Remove old section (between "## Context Bus" and next "##" or EOF)
            sed -i.tmp '/^## Context Bus/,/^## [^C]/{ /^## [^C]/!d; }' "$WORKSPACE/HEARTBEAT.md" 2>/dev/null || \
            sed -i '' '/^## Context Bus/,/^## [^C]/{ /^## [^C]/!d; }' "$WORKSPACE/HEARTBEAT.md" 2>/dev/null || true
            rm -f "$WORKSPACE/HEARTBEAT.md.tmp"
        fi
        echo "$HEARTBEAT_RULES" >> "$WORKSPACE/HEARTBEAT.md"
        echo "   ✅ Added Context Bus v3 rules to HEARTBEAT.md"
    else
        echo "   ⏭️  HEARTBEAT.md already has Context Bus v3 rules"
    fi
else
    cat > "$WORKSPACE/HEARTBEAT.md" << EOF
# HEARTBEAT.md
$HEARTBEAT_RULES
EOF
    echo "   ✅ Created HEARTBEAT.md with Context Bus v3 rules"
fi

# Create/update AGENTS.md reference
echo ""
echo "📄 Updating AGENTS.md..."
if [[ -f "$WORKSPACE/AGENTS.md" ]]; then
    if ! grep -q "Context Bus" "$WORKSPACE/AGENTS.md" 2>/dev/null; then
        cat >> "$WORKSPACE/AGENTS.md" << 'EOF'

## Context Bus Integration

On session start, read these files for handoff context:
- `.context-bus/handoff.json` — Task state, recent actions, next steps
- `.context-bus/rolling-summary.md` — Session summary from previous model

These contain context from the previous model if a switch occurred.
EOF
        echo "   ✅ Added Context Bus reference to AGENTS.md"
    else
        echo "   ⏭️  AGENTS.md already has Context Bus reference"
    fi
else
    echo "   ⏭️  No AGENTS.md found (will use HEARTBEAT.md)"
fi

# Set up background monitor
echo ""
echo "⏰ Setting up background monitor..."
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: use launchd
    PLIST_FILE="${HOME}/Library/LaunchAgents/com.contextbus.monitor.plist"
    
    # Unload if exists
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.contextbus.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>${CONTEXT_DIR}/usage-monitor.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>CONTEXT_BUS_WORKSPACE</key>
        <string>${WORKSPACE}</string>
    </dict>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>StandardOutPath</key>
    <string>${CONTEXT_DIR}/monitor.log</string>
    <key>StandardErrorPath</key>
    <string>${CONTEXT_DIR}/monitor.err</string>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    launchctl load "$PLIST_FILE" 2>/dev/null || true
    echo "   ✅ LaunchAgent installed (runs every 5 min)"
else
    # Linux: use cron
    CRON_CMD="*/5 * * * * CONTEXT_BUS_WORKSPACE='$WORKSPACE' ${CONTEXT_DIR}/usage-monitor.sh >> ${CONTEXT_DIR}/monitor.log 2>&1"
    
    if ! crontab -l 2>/dev/null | grep -q "context-bus"; then
        (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
        echo "   ✅ Cron job installed (runs every 5 min)"
    else
        echo "   ⏭️  Cron job already exists"
    fi
fi

# Print summary
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Context Bus v3 installed successfully!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📁 Installed files:"
echo "   $CONTEXT_DIR/handoff.json"
echo "   $CONTEXT_DIR/usage-monitor.sh"
echo "   $CONTEXT_DIR/handoff-utils.sh"
echo "   $CONFIG_DIR/config.yaml"
echo ""
echo "🎯 How it works:"
echo "   • Heartbeat updates handoff.json with current state"
echo "   • Monitor checks every 5 min (2 min at >70% usage)"
echo "   • At 95% usage → auto-switch to Codex"
echo "   • At <50% usage + idle → auto-switch back to Opus"
echo "   • You get notified on every switch"
echo ""
echo "⚙️  Optional: Edit $CONFIG_DIR/config.yaml"
echo "   • Set your Telegram chat ID for notifications"
echo "   • Adjust thresholds as needed"
echo ""
echo "🚀 You're ready to go!"
