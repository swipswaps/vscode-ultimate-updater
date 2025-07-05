# Usage Guide

## Command Line Options

```bash
./vscode_ultimate_updater.sh [OPTIONS]

OPTIONS:
    --dry-run, -d           Run in simulation mode (no real changes)
    --verbose, -v           Enable verbose output
    --force, -f             Force update even if current version is latest
    --skip-backup, -s       Skip creating backup (not recommended)
    --help, -h              Show help message
```

## Basic Usage

### 1. Test First (Recommended)
```bash
# Basic dry run - see what would happen
./vscode_ultimate_updater.sh --dry-run

# Verbose dry run - detailed analysis
./vscode_ultimate_updater.sh --dry-run --verbose
```

### 2. Normal Update
```bash
# Standard update with all safety features
./vscode_ultimate_updater.sh

# Update with detailed output
./vscode_ultimate_updater.sh --verbose
```

### 3. Force Update
```bash
# Force update regardless of version check
./vscode_ultimate_updater.sh --force
```

## Advanced Usage

### Automation
```bash
# For CI/CD or automated scripts
./vscode_ultimate_updater.sh --force --skip-backup --verbose

# With error handling
if ./vscode_ultimate_updater.sh --dry-run; then
    ./vscode_ultimate_updater.sh
else
    echo "Dry run failed, aborting update"
    exit 1
fi
```

### Troubleshooting
```bash
# Maximum verbosity for debugging
./vscode_ultimate_updater.sh --verbose --dry-run

# Check specific issues
./vscode_ultimate_updater.sh --help
```

## Workflow Examples

### First-Time User
```bash
# 1. Test the script
./vscode_ultimate_updater.sh --dry-run

# 2. Review what it would do
# 3. Run the actual update
./vscode_ultimate_updater.sh

# 4. Verify VSCode works correctly
code-insiders --version
```

### Regular Updates
```bash
# Quick check and update
./vscode_ultimate_updater.sh

# Or with verification first
./vscode_ultimate_updater.sh --dry-run && ./vscode_ultimate_updater.sh
```

### Development Environment
```bash
# Force update to latest insider build
./vscode_ultimate_updater.sh --force

# Update with full logging
./vscode_ultimate_updater.sh --verbose 2>&1 | tee update.log
```

## Safety Features

### Automatic Safety Checks
The script automatically:
- ✅ Detects if running inside VSCode
- ✅ Launches external terminal if unsafe
- ✅ Creates backups before changes
- ✅ Verifies file integrity
- ✅ Provides rollback options

### Manual Safety Options
```bash
# Skip backup (faster but less safe)
./vscode_ultimate_updater.sh --skip-backup

# Dry run to verify safety
./vscode_ultimate_updater.sh --dry-run
```

## Understanding Output

### Dry Run Output
```
🧪 [DRY RUN] Would create backup: ~/.vscode-backups-dry-run/20250704_123456_pre-update_insiders
🧪 [DRY RUN] Would download: 85MB
🧪 [DRY RUN] Would install: VSCode Insiders update
🧪 [DRY RUN] Would apply: 5 performance optimizations
```

### Real Mode Output
```
📦 Creating pre-update backup...
⬇️  Starting optimized download...
🔧 Installing VSCode insiders update...
🚀 Applying performance optimizations...
✅ Update completed successfully!
```

### Error Handling
```
❌ VSCode is running - please close it first
💡 To update safely:
   1. Save all your work in VSCode
   2. Close VSCode completely
   3. Run this script again
```

## Performance Optimizations Applied

The script automatically applies these optimizations:

### Telemetry Elimination
```json
{
    "telemetry.telemetryLevel": "off",
    "workbench.enableExperiments": false
}
```

### Augment Extension Optimization
```json
{
    "augment.auth.tokenRefreshInterval": 3600000,
    "augment.network.timeout": 60000
}
```

### Memory Optimization
```json
{
    "editor.minimap.enabled": false,
    "editor.codeLens": false,
    "breadcrumbs.enabled": false
}
```

### File System Optimization
```json
{
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/node_modules/**": true
    }
}
```

## Backup and Restore

### Backup Locations
- **Settings**: `~/.vscode-backups/TIMESTAMP_pre-update_VARIANT/settings/`
- **Extensions**: `~/.vscode-backups/TIMESTAMP_pre-update_VARIANT/extensions/`
- **Workspaces**: `~/.vscode-backups/TIMESTAMP_pre-update_VARIANT/workspaces/`

### Manual Restore
```bash
# Find latest backup
ls -la ~/.vscode-backups/

# Restore settings (example)
cp ~/.vscode-backups/20250704_123456_pre-update_insiders/settings/* \
   ~/.config/Code\ -\ Insiders/User/
```

## Cross-Platform Notes

### Linux
- Uses RPM packages by default
- Requires sudo for installation
- Supports all major distributions

### macOS
- Downloads ZIP archives
- Installs to /Applications
- Requires admin privileges

### Windows (WSL)
- Downloads EXE installers
- Silent installation mode
- Works in WSL2 environment

## Common Scenarios

### Scenario 1: Already Up-to-Date
```bash
$ ./vscode_ultimate_updater.sh --dry-run
✅ File is up-to-date and complete - no download needed
✅ All settings already optimized
```

### Scenario 2: Update Available
```bash
$ ./vscode_ultimate_updater.sh --dry-run
📥 Update available - will download 85MB
🔄 5 settings optimizations will be applied
```

### Scenario 3: VSCode Running
```bash
$ ./vscode_ultimate_updater.sh
⚠️  VSCode insiders is currently running (16 processes)
What would you like to do?
1. 🛑 Close VSCode gracefully and continue update (RECOMMENDED)
```

## Tips and Best Practices

### Before Running
1. **Save all work** in VSCode
2. **Close VSCode** completely
3. **Test with dry run** first

### Regular Maintenance
1. **Run weekly** for latest updates
2. **Keep backups** for safety
3. **Monitor performance** improvements

### Troubleshooting
1. **Use verbose mode** for debugging
2. **Check logs** in dry run mode
3. **Verify permissions** if issues occur

## Next Steps

- **[Troubleshooting Guide](TROUBLESHOOTING.md)** for common issues
- **[Performance Guide](PERFORMANCE.md)** for optimization details
- **[GitHub Issues](https://github.com/swipswaps/vscode-ultimate-updater/issues)** for support
