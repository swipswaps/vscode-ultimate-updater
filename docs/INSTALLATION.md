# Installation Guide

## Quick Installation

### 1. Clone Repository
```bash
git clone https://github.com/swipswaps/vscode-ultimate-updater.git
cd vscode-ultimate-updater
```

### 2. Make Executable
```bash
chmod +x vscode_ultimate_updater.sh
```

### 3. Test Installation
```bash
./vscode_ultimate_updater.sh --help
./vscode_ultimate_updater.sh --dry-run
```

## Platform-Specific Setup

### Linux
```bash
# Install dependencies (most distributions)
sudo apt update && sudo apt install curl git

# Or for RPM-based systems
sudo dnf install curl git

# Clone and setup
git clone https://github.com/swipswaps/vscode-ultimate-updater.git
cd vscode-ultimate-updater
chmod +x vscode_ultimate_updater.sh
```

### macOS
```bash
# Install Xcode Command Line Tools if not already installed
xcode-select --install

# Clone and setup
git clone https://github.com/swipswaps/vscode-ultimate-updater.git
cd vscode-ultimate-updater
chmod +x vscode_ultimate_updater.sh
```

### Windows (WSL2)
```bash
# In WSL2 terminal
git clone https://github.com/swipswaps/vscode-ultimate-updater.git
cd vscode-ultimate-updater
chmod +x vscode_ultimate_updater.sh
```

## System Requirements

### Minimum Requirements
- **Bash 4.0+** (included in most modern systems)
- **curl** (for downloads)
- **ps, grep, awk** (standard Unix tools)

### Recommended
- **Python 3** (for advanced JSON settings merging)
- **Terminal emulator** (konsole, gnome-terminal, xterm, etc.)
- **sudo access** (for VSCode installation)

## Verification

### Test Basic Functionality
```bash
# Check help system
./vscode_ultimate_updater.sh --help

# Test dry run
./vscode_ultimate_updater.sh --dry-run

# Test verbose mode
./vscode_ultimate_updater.sh --dry-run --verbose
```

### Expected Output
```
Ultimate VSCode Updater v2.1.0 (DRY RUN)
🔍 DRY RUN MODE: Simulating all operations without making real changes
🔍 Detected: VSCode insiders on linux
✅ [DRY RUN] Safe to proceed with update simulation
```

## Troubleshooting Installation

### Permission Issues
```bash
# Fix permissions
chmod +x vscode_ultimate_updater.sh

# If still issues, check file ownership
ls -la vscode_ultimate_updater.sh
```

### Missing Dependencies
```bash
# Check curl
which curl || echo "curl not found"

# Check bash version
bash --version

# Install missing tools (Ubuntu/Debian)
sudo apt install curl git bash

# Install missing tools (CentOS/RHEL/Fedora)
sudo dnf install curl git bash
```

### VSCode Not Found
```bash
# Check VSCode installation
which code || which code-insiders

# If not found, install VSCode first:
# https://code.visualstudio.com/download
```

## Advanced Setup

### Global Installation
```bash
# Copy to system path (optional)
sudo cp vscode_ultimate_updater.sh /usr/local/bin/vscode-update
sudo chmod +x /usr/local/bin/vscode-update

# Now you can run from anywhere
vscode-update --dry-run
```

### Alias Setup
```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'alias vscode-update="/path/to/vscode_ultimate_updater.sh"' >> ~/.bashrc
source ~/.bashrc

# Usage
vscode-update --dry-run
```

### Automation Setup
```bash
# For automated environments
export VSCODE_UPDATER_PATH="/path/to/vscode_ultimate_updater.sh"
$VSCODE_UPDATER_PATH --dry-run --verbose
```

## Next Steps

After installation:
1. **Read [Usage Guide](USAGE.md)** for detailed usage instructions
2. **Run dry run test** to verify everything works
3. **Check [Troubleshooting](TROUBLESHOOTING.md)** if you encounter issues
4. **Review [Performance Guide](PERFORMANCE.md)** for optimization details
