#!/bin/bash
# Context Bus Uninstaller

set -e

CONTEXT_BUS_DIR="${HOME}/.context-bus"
CONFIG_DIR="${HOME}/.config/context-bus"

echo "🗑️  Uninstalling Context Bus..."
echo ""

# Remove directories
if [[ -d "$CONTEXT_BUS_DIR" ]]; then
    echo "Removing $CONTEXT_BUS_DIR..."
    rm -rf "$CONTEXT_BUS_DIR"
fi

if [[ -d "$CONFIG_DIR" ]]; then
    echo "Removing $CONFIG_DIR..."
    rm -rf "$CONFIG_DIR"
fi

# Remove from PATH (best effort)
SHELL_RC=""
if [[ -f "${HOME}/.zshrc" ]]; then
    SHELL_RC="${HOME}/.zshrc"
elif [[ -f "${HOME}/.bashrc" ]]; then
    SHELL_RC="${HOME}/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if grep -q "context-bus" "$SHELL_RC" 2>/dev/null; then
        echo "Removing PATH entry from $SHELL_RC..."
        sed -i.bak '/context-bus/d' "$SHELL_RC" 2>/dev/null || \
        sed -i '' '/context-bus/d' "$SHELL_RC" 2>/dev/null || true
    fi
fi

echo ""
echo "✅ Context Bus uninstalled successfully!"
echo ""
echo "Note: HEARTBEAT.md rules were not removed. Edit manually if needed."
