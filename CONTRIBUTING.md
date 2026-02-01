# Contributing to Context Bus

Thank you for your interest in contributing! Here's how you can help.

## Ways to Contribute

### 🐛 Bug Reports

1. Check existing issues first
2. Include your OS, shell, and agent versions
3. Provide steps to reproduce
4. Include relevant config (sanitize secrets!)

### ✨ Feature Requests

1. Describe the use case
2. Explain why existing features don't solve it
3. Propose a solution if you have one

### 🔧 Pull Requests

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test on your system
5. Commit with clear messages
6. Push and create a PR

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/context-bus.git
cd context-bus

# Test the install script
./install.sh

# Make changes to scripts/
vim scripts/model-router.sh

# Test your changes
~/.context-bus/model-router.sh
```

## Code Style

- Shell scripts: Use `set -e` and proper quoting
- YAML: 2-space indentation
- Markdown: Follow existing formatting

## Adding New Models

1. Add to `config.template.yaml` under `models:`
2. Update the switch logic in `model-router.sh`
3. Add detection to `install.sh`
4. Update README.md with install instructions

## Adding New Notification Channels

1. Create `notifications/your-channel.sh`
2. Add config section in `config.template.yaml`
3. Update install script to detect config
4. Document in README.md

## Testing

Currently testing is manual. Please test:
- Fresh install
- Upgrade from previous version
- All supported platforms (macOS, Linux, Windows/WSL)
- With and without optional dependencies (qmd, ollama)

## Questions?

Open an issue with the `question` label.
