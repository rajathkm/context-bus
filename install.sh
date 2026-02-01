#!/bin/bash
# Context Bus Installer
# Automatic model switching for AI coding agents with full context preservation

set -e

CONTEXT_BUS_DIR="${HOME}/.context-bus"
CONFIG_DIR="${HOME}/.config/context-bus"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="${PWD}"

echo ""
echo "🚀 Context Bus Installer"
echo "========================"
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p "$CONTEXT_BUS_DIR/sessions"
mkdir -p "$CONFIG_DIR"
echo "   ✅ ~/.context-bus/"
echo "   ✅ ~/.config/context-bus/"

# Copy scripts
echo ""
echo "📜 Installing scripts..."
if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
    cp -r "${SCRIPT_DIR}/scripts/"* "$CONTEXT_BUS_DIR/"
    chmod +x "$CONTEXT_BUS_DIR/"*.sh
    echo "   ✅ Scripts installed to ~/.context-bus/"
else
    echo "   ⚠️  Scripts directory not found, downloading..."
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/model-router.sh -o "$CONTEXT_BUS_DIR/model-router.sh"
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/context-handoff.sh -o "$CONTEXT_BUS_DIR/context-handoff.sh"
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/update-usage.sh -o "$CONTEXT_BUS_DIR/update-usage.sh"
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/update-handoff.sh -o "$CONTEXT_BUS_DIR/update-handoff.sh"
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/refresh-summary.sh -o "$CONTEXT_BUS_DIR/refresh-summary.sh"
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/semantic-context.sh -o "$CONTEXT_BUS_DIR/semantic-context.sh"
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/update-state.sh -o "$CONTEXT_BUS_DIR/update-state.sh"
    curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/scripts/auto-update-task.sh -o "$CONTEXT_BUS_DIR/auto-update-task.sh"
    chmod +x "$CONTEXT_BUS_DIR/"*.sh
    echo "   ✅ Scripts downloaded"
fi

# Create config if not exists
echo ""
echo "⚙️  Setting up configuration..."
if [[ ! -f "${CONFIG_DIR}/config.yaml" ]]; then
    if [[ -f "${SCRIPT_DIR}/config.template.yaml" ]]; then
        cp "${SCRIPT_DIR}/config.template.yaml" "${CONFIG_DIR}/config.yaml"
    else
        curl -fsSL https://raw.githubusercontent.com/rajathkm/context-bus/main/config.template.yaml -o "${CONFIG_DIR}/config.yaml"
    fi
    echo "   ✅ Created ~/.config/context-bus/config.yaml"
else
    echo "   ⏭️  Config already exists"
fi

# Initialize handoff.json
echo ""
echo "📝 Initializing context files..."
if [[ ! -f "${CONTEXT_BUS_DIR}/handoff.json" ]]; then
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
    echo "   ✅ Created handoff.json"
fi

if [[ ! -f "${CONTEXT_BUS_DIR}/rolling-summary.md" ]]; then
    cat > "${CONTEXT_BUS_DIR}/rolling-summary.md" << EOF
# Session Summary
Last updated: $(date +"%Y-%m-%d %H:%M")

## Current Focus
Context Bus initialized. Ready for work.

## Recent Progress
- Context Bus installed

## Key Decisions
- None yet

## Open Questions
- None
EOF
    echo "   ✅ Created rolling-summary.md"
fi

# Create workspace context files if in a project directory
echo ""
echo "📄 Setting up workspace context..."
if [[ "$WORKSPACE" != "$HOME" ]] && [[ -d "$WORKSPACE" ]]; then
    if [[ ! -f "${WORKSPACE}/AGENTS.md" ]]; then
        cat > "${WORKSPACE}/AGENTS.md" << 'EOF'
# AGENTS.md - Shared Agent Context

This file is read by ALL models (Claude, Codex, Gemini, Local).
Edit once, all agents see the same context.

## Project Context

Project: [Your Project Name]
Description: [What you're building]

## Current Task

Task: None
Status: idle

## Key Constraints

- Follow existing code patterns
- Write tests for new features
- Ask before making breaking changes

## Important Files

- README.md

## Decisions Made

- (None yet)

## Notes for All Models

- Context Bus is installed and active
- Models will auto-switch at 95% usage
- Context is preserved across switches
EOF
        echo "   ✅ Created AGENTS.md in workspace"
    else
        echo "   ⏭️  AGENTS.md already exists"
    fi
    
    if [[ ! -f "${WORKSPACE}/MEMORY.md" ]]; then
        cat > "${WORKSPACE}/MEMORY.md" << 'EOF'
# MEMORY.md - Long-Term Memory

This file persists across sessions and model switches.
All models read and update this file.

## Important Context

- Context Bus installed for automatic model switching

## Lessons Learned

- (Add lessons as you learn them)

## User Preferences

- (Add your preferences)

## Project History

### $(date +"%Y-%m-%d")
- Context Bus initialized
EOF
        echo "   ✅ Created MEMORY.md in workspace"
    else
        echo "   ⏭️  MEMORY.md already exists"
    fi
fi

# Set up HEARTBEAT.md for OpenClaw/Clawdbot
echo ""
echo "🤖 Setting up agent integration..."
if [[ -f "${WORKSPACE}/HEARTBEAT.md" ]]; then
    if ! grep -q "Context Bus" "${WORKSPACE}/HEARTBEAT.md" 2>/dev/null; then
        echo "" >> "${WORKSPACE}/HEARTBEAT.md"
        cat >> "${WORKSPACE}/HEARTBEAT.md" << 'EOF'

## Context Bus Auto-Switch

Check usage via `session_status`. If >= 95%:
1. Run `~/.context-bus/context-handoff.sh opus codex auto_threshold`
2. Notify user: "🔄 Auto-switched to Codex"

If usage < 50% AND on codex AND tasks idle:
1. Run `~/.context-bus/model-router.sh --reset`
2. Notify user: "🔄 Switched back to Opus"
EOF
        echo "   ✅ Added Context Bus rules to HEARTBEAT.md"
    else
        echo "   ⏭️  HEARTBEAT.md already has Context Bus rules"
    fi
else
    echo "   ℹ️  No HEARTBEAT.md found (not using OpenClaw?)"
fi

# Add to PATH
echo ""
echo "🔗 Updating PATH..."
SHELL_RC=""
if [[ -f "${HOME}/.zshrc" ]]; then
    SHELL_RC="${HOME}/.zshrc"
elif [[ -f "${HOME}/.bashrc" ]]; then
    SHELL_RC="${HOME}/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q "context-bus" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Context Bus" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:${CONTEXT_BUS_DIR}\"" >> "$SHELL_RC"
        echo "   ✅ Added to PATH in $SHELL_RC"
    else
        echo "   ⏭️  Already in PATH"
    fi
fi

# Print success
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Context Bus installed successfully!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📁 Installed files:"
echo "   ~/.context-bus/           Scripts + state"
echo "   ~/.config/context-bus/    Configuration"
if [[ "$WORKSPACE" != "$HOME" ]]; then
echo "   ${WORKSPACE}/AGENTS.md    Shared context"
echo "   ${WORKSPACE}/MEMORY.md    Long-term memory"
fi
echo ""
echo "⚙️  One-time setup (optional):"
echo "   1. Edit ~/.config/context-bus/config.yaml"
echo "   2. Set your Telegram chat ID for notifications"
echo ""
echo "🎯 How it works:"
echo "   • All models read AGENTS.md and MEMORY.md"
echo "   • At 95% Opus usage → auto-switch to Codex"
echo "   • When limits reset → auto-switch back to Opus"
echo "   • Context preserved via handoff.json"
echo ""
echo "📖 Documentation: https://github.com/rajathkm/context-bus"
echo ""
echo "🚀 You're ready to go!"
