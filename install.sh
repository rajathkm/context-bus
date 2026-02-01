#!/bin/bash
# Context Bus Installer
# Automatic model switching for AI coding agents

set -e

CONTEXT_BUS_DIR="${HOME}/.context-bus"
CONFIG_DIR="${HOME}/.config/context-bus"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Installing Context Bus..."
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p "$CONTEXT_BUS_DIR/sessions"
mkdir -p "$CONFIG_DIR"

# Copy scripts
echo "📜 Installing scripts..."
if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
    cp -r "${SCRIPT_DIR}/scripts/"* "$CONTEXT_BUS_DIR/"
    chmod +x "$CONTEXT_BUS_DIR/"*.sh
fi

# Create config if not exists
if [[ ! -f "${CONFIG_DIR}/config.yaml" ]]; then
    echo "⚙️  Creating default config..."
    cp "${SCRIPT_DIR}/config.template.yaml" "${CONFIG_DIR}/config.yaml"
    echo "   Edit ~/.config/context-bus/config.yaml to customize"
fi

# Initialize handoff.json
if [[ ! -f "${CONTEXT_BUS_DIR}/handoff.json" ]]; then
    echo "📝 Initializing handoff.json..."
    cat > "${CONTEXT_BUS_DIR}/handoff.json" << 'EOF'
{
  "version": 1,
  "timestamp": null,
  "task": {
    "id": null,
    "description": null,
    "status": "idle",
    "complexity": null
  },
  "model": {
    "current": "opus",
    "previous": null,
    "switch_reason": null,
    "usage_percent": null
  },
  "context_refs": ["AGENTS.md", "MEMORY.md"],
  "recent_actions": [],
  "blockers": [],
  "next_steps": [],
  "notes": {}
}
EOF
fi

# Initialize rolling-summary.md
if [[ ! -f "${CONTEXT_BUS_DIR}/rolling-summary.md" ]]; then
    echo "📝 Initializing rolling-summary.md..."
    cat > "${CONTEXT_BUS_DIR}/rolling-summary.md" << EOF
# Session Summary
Last updated: $(date +"%Y-%m-%d %H:%M")

## Current Focus
Context Bus initialized. No active task.

## Recent Progress
- Context Bus installed

## Key Decisions
- None yet

## Open Questions
- None
EOF
fi

# Add to PATH (optional)
SHELL_RC=""
if [[ -f "${HOME}/.zshrc" ]]; then
    SHELL_RC="${HOME}/.zshrc"
elif [[ -f "${HOME}/.bashrc" ]]; then
    SHELL_RC="${HOME}/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q "context-bus" "$SHELL_RC" 2>/dev/null; then
        echo "🔗 Adding to PATH..."
        echo "" >> "$SHELL_RC"
        echo "# Context Bus" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:${CONTEXT_BUS_DIR}\"" >> "$SHELL_RC"
    fi
fi

# Print success
echo ""
echo "✅ Context Bus installed successfully!"
echo ""
echo "📁 Files:"
echo "   Scripts: ${CONTEXT_BUS_DIR}/"
echo "   Config:  ${CONFIG_DIR}/config.yaml"
echo "   State:   ${CONTEXT_BUS_DIR}/handoff.json"
echo ""
echo "🔧 Next steps:"
echo "   1. Edit ~/.config/context-bus/config.yaml"
echo "   2. Set your Telegram chat ID for notifications"
echo "   3. Add Context Bus rules to your HEARTBEAT.md"
echo ""
echo "📖 Documentation:"
echo "   https://github.com/openclaw/context-bus"
echo ""
echo "🎉 Ready to go!"
