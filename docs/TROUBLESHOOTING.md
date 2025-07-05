# Troubleshooting Guide

## Common Issues and Solutions

### 1. Permission Denied Errors

**Problem**: Script won't execute
```bash
bash: ./vscode_ultimate_updater.sh: Permission denied
```

**Solution**:
```bash
chmod +x vscode_ultimate_updater.sh
```

### 2. VSCode Not Found

**Problem**: Script can't detect VSCode
```bash
❌ No VSCode installation detected
```

**Solutions**:
```bash
# Check if VSCode is installed
which code || which code-insiders

# Install VSCode if missing
# Download from: https://code.visualstudio.com/download

# Add to PATH if installed but not found
export PATH="$PATH:/usr/share/code-insiders/bin"
```

### 3. Download Failures

**Problem**: Network or download issues
```bash
❌ Download failed after 3 attempts
```

**Solutions**:
```bash
# Check internet connection
curl -I https://code.visualstudio.com/

# Try with verbose mode
./vscode_ultimate_updater.sh --verbose

# Check firewall/proxy settings
# Clear download cache
rm -rf ~/.cache/vscode-updates/*
```

### 4. Backup Creation Fails

**Problem**: Cannot create backup
```bash
❌ Failed to create backup directory
```

**Solutions**:
```bash
# Check disk space
df -h

# Check permissions
ls -la ~/.vscode-backups/

# Create directory manually
mkdir -p ~/.vscode-backups
chmod 755 ~/.vscode-backups

# Skip backup if necessary (not recommended)
./vscode_ultimate_updater.sh --skip-backup
```

### 5. Installation Fails

**Problem**: Package installation errors
```bash
❌ Installation failed
```

**Solutions**:

#### Linux (RPM)
```bash
# Check if rpm is available
which rpm

# Try manual installation
sudo rpm -Uvh /path/to/downloaded/file.rpm

# For DEB systems, convert RPM
sudo alien downloaded-file.rpm
sudo dpkg -i converted-file.deb
```

#### macOS
```bash
# Check admin privileges
sudo -v

# Verify download integrity
file downloaded-file.zip

# Manual extraction and installation
unzip downloaded-file.zip
sudo cp -R "Visual Studio Code - Insiders.app" /Applications/
```

### 6. Settings Optimization Fails

**Problem**: Cannot update settings
```bash
❌ Failed to merge settings
```

**Solutions**:
```bash
# Check Python availability
python3 --version

# Check settings file permissions
ls -la ~/.config/Code*/User/settings.json

# Fix permissions
chmod 644 ~/.config/Code*/User/settings.json

# Manual settings backup
cp ~/.config/Code*/User/settings.json ~/.config/Code*/User/settings.json.bak
```

### 7. Process Detection Issues

**Problem**: Cannot detect VSCode processes
```bash
❌ Process detection failed
```

**Solutions**:
```bash
# Check process manually
ps aux | grep code

# Verify process tools
which ps pstree

# Try alternative detection
pgrep -f code-insiders
```

### 8. External Terminal Launch Fails

**Problem**: Cannot launch external terminal
```bash
❌ No terminal emulator found!
```

**Solutions**:
```bash
# Install a terminal emulator
sudo apt install konsole          # KDE
sudo apt install gnome-terminal   # GNOME
sudo apt install xfce4-terminal   # XFCE
sudo apt install xterm            # Universal

# Check available terminals
which konsole gnome-terminal xfce4-terminal xterm

# Set DISPLAY if using SSH
export DISPLAY=:0
```

## Platform-Specific Issues

### Linux Issues

#### SELinux Problems
```bash
# Check SELinux status
sestatus

# Temporarily disable if needed
sudo setenforce 0

# Or add exception
sudo setsebool -P allow_execstack 1
```

#### Package Manager Issues
```bash
# For RPM systems without rpm command
sudo dnf install rpm

# For systems with only dpkg
sudo apt install alien
alien downloaded-file.rpm
sudo dpkg -i converted-file.deb
```

### macOS Issues

#### Gatekeeper Problems
```bash
# If macOS blocks execution
sudo spctl --master-disable

# Or allow specific file
sudo xattr -rd com.apple.quarantine vscode_ultimate_updater.sh
```

#### Permission Issues
```bash
# Grant full disk access in System Preferences
# Security & Privacy > Privacy > Full Disk Access

# Or run with sudo (not recommended)
sudo ./vscode_ultimate_updater.sh
```

### Windows (WSL) Issues

#### WSL Version Problems
```bash
# Check WSL version
wsl --version

# Upgrade to WSL2 if needed
wsl --set-default-version 2
```

#### Windows Path Issues
```bash
# Convert Windows paths
wslpath "C:\Users\username\AppData\Local\Programs\Microsoft VS Code Insiders"
```

## Debugging Steps

### 1. Enable Verbose Mode
```bash
./vscode_ultimate_updater.sh --dry-run --verbose
```

### 2. Check System Requirements
```bash
# Bash version
bash --version

# Required tools
which curl ps grep awk

# Optional tools
which python3 pstree wmctrl
```

### 3. Manual Testing
```bash
# Test VSCode detection
code-insiders --version

# Test download URL
curl -I "https://code.visualstudio.com/sha/download?build=insider&os=linux-rpm-x64"

# Test process detection
ps aux | grep code-insiders
```

### 4. Check Logs
```bash
# Dry run logs
ls -la ~/.vscode-dry-run-*.log
tail -f ~/.vscode-dry-run-*.log

# System logs
journalctl -f | grep code
```

## Recovery Procedures

### 1. Restore from Backup
```bash
# Find latest backup
ls -la ~/.vscode-backups/

# Restore settings
BACKUP_DIR="~/.vscode-backups/LATEST_BACKUP"
cp "$BACKUP_DIR/settings/"* ~/.config/Code*/User/

# Restore extensions
code-insiders --install-extension $(cat "$BACKUP_DIR/extensions/extensions.txt")
```

### 2. Clean Installation
```bash
# Remove VSCode completely
sudo rpm -e code-insiders  # Linux RPM
# or
sudo rm -rf "/Applications/Visual Studio Code - Insiders.app"  # macOS

# Clear all data
rm -rf ~/.config/Code*
rm -rf ~/.vscode*

# Reinstall VSCode
# Download from: https://code.visualstudio.com/insiders/
```

### 3. Reset Script State
```bash
# Clear download cache
rm -rf ~/.cache/vscode-updates*

# Clear dry run logs
rm -f ~/.vscode-dry-run-*.log

# Reset permissions
chmod +x vscode_ultimate_updater.sh
```

## Getting Help

### 1. Collect Debug Information
```bash
# System info
uname -a
bash --version
code-insiders --version

# Script output
./vscode_ultimate_updater.sh --dry-run --verbose > debug.log 2>&1
```

### 2. Check Known Issues
- [GitHub Issues](https://github.com/swipswaps/vscode-ultimate-updater/issues)
- [GitHub Discussions](https://github.com/swipswaps/vscode-ultimate-updater/discussions)

### 3. Report New Issues
Include in your report:
- Operating system and version
- VSCode variant (stable/insiders)
- Script output with `--verbose`
- Steps to reproduce

## Prevention Tips

### 1. Regular Maintenance
```bash
# Keep system updated
sudo apt update && sudo apt upgrade  # Debian/Ubuntu
sudo dnf update                       # Fedora/RHEL

# Clean old backups periodically
find ~/.vscode-backups -type d -mtime +30 -exec rm -rf {} \;
```

### 2. Monitor Resources
```bash
# Check disk space before updates
df -h

# Monitor memory usage
free -h

# Check for conflicting processes
ps aux | grep code
```

### 3. Test Regularly
```bash
# Weekly dry run test
./vscode_ultimate_updater.sh --dry-run

# Verify backups work
ls -la ~/.vscode-backups/
```
