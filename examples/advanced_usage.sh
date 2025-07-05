#!/bin/bash
################################################################################
# Advanced Usage Examples for VSCode Ultimate Updater
################################################################################

echo "VSCode Ultimate Updater - Advanced Usage Examples"
echo "================================================="

# Example 1: Automated update with error handling
echo ""
echo "Example 1: Automated update with error handling"
echo "-----------------------------------------------"
cat << 'EOF'
#!/bin/bash
# Automated update script with comprehensive error handling

set -euo pipefail

UPDATER_PATH="./vscode_ultimate_updater.sh"
LOG_FILE="update_$(date +%Y%m%d_%H%M%S).log"

echo "Starting automated VSCode update..."

# Step 1: Test first
if ! "$UPDATER_PATH" --dry-run --verbose > "$LOG_FILE" 2>&1; then
    echo "❌ Dry run failed - check $LOG_FILE"
    exit 1
fi

echo "✅ Dry run successful"

# Step 2: Run actual update
if "$UPDATER_PATH" --verbose >> "$LOG_FILE" 2>&1; then
    echo "✅ Update completed successfully"
    echo "📝 Log saved to: $LOG_FILE"
else
    echo "❌ Update failed - check $LOG_FILE"
    exit 1
fi
EOF

echo ""

# Example 2: Conditional update based on version
echo "Example 2: Conditional update based on version"
echo "----------------------------------------------"
cat << 'EOF'
#!/bin/bash
# Only update if specific conditions are met

CURRENT_VERSION=$(code-insiders --version | head -1)
echo "Current version: $CURRENT_VERSION"

# Check if update is actually needed
if ./vscode_ultimate_updater.sh --dry-run | grep -q "No update needed"; then
    echo "✅ Already up-to-date, skipping update"
    exit 0
else
    echo "🔄 Update available, proceeding..."
    ./vscode_ultimate_updater.sh --verbose
fi
EOF

echo ""

# Example 3: Backup verification before update
echo "Example 3: Backup verification before update"
echo "--------------------------------------------"
cat << 'EOF'
#!/bin/bash
# Verify backup integrity before proceeding

BACKUP_DIR="$HOME/.vscode-backups"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR" | head -1)

if [[ -n "$LATEST_BACKUP" ]]; then
    echo "📦 Latest backup: $LATEST_BACKUP"
    
    # Verify backup completeness
    if [[ -f "$BACKUP_DIR/$LATEST_BACKUP/manifest.json" ]]; then
        echo "✅ Backup manifest found"
        ./vscode_ultimate_updater.sh
    else
        echo "⚠️  Backup incomplete, creating new backup"
        ./vscode_ultimate_updater.sh --force
    fi
else
    echo "📦 No existing backup, will create one"
    ./vscode_ultimate_updater.sh
fi
EOF

echo ""

# Example 4: Performance monitoring
echo "Example 4: Performance monitoring"
echo "---------------------------------"
cat << 'EOF'
#!/bin/bash
# Monitor performance before and after update

echo "📊 Performance monitoring during update"

# Measure before
BEFORE_MEMORY=$(ps aux | grep code-insiders | awk '{sum+=$6} END {print sum}')
BEFORE_PROCESSES=$(ps aux | grep code-insiders | wc -l)

echo "Before update:"
echo "  Memory: ${BEFORE_MEMORY}KB"
echo "  Processes: $BEFORE_PROCESSES"

# Run update
./vscode_ultimate_updater.sh --verbose

# Wait for VSCode to start
sleep 10
code-insiders &
sleep 5

# Measure after
AFTER_MEMORY=$(ps aux | grep code-insiders | awk '{sum+=$6} END {print sum}')
AFTER_PROCESSES=$(ps aux | grep code-insiders | wc -l)

echo "After update:"
echo "  Memory: ${AFTER_MEMORY}KB"
echo "  Processes: $AFTER_PROCESSES"

# Calculate improvement
if [[ $AFTER_MEMORY -lt $BEFORE_MEMORY ]]; then
    IMPROVEMENT=$(( (BEFORE_MEMORY - AFTER_MEMORY) * 100 / BEFORE_MEMORY ))
    echo "✅ Memory improvement: ${IMPROVEMENT}%"
else
    echo "⚠️  Memory usage increased"
fi
EOF

echo ""

# Example 5: Multi-environment deployment
echo "Example 5: Multi-environment deployment"
echo "--------------------------------------"
cat << 'EOF'
#!/bin/bash
# Deploy updates across multiple environments

ENVIRONMENTS=("development" "staging" "production")
UPDATER_PATH="./vscode_ultimate_updater.sh"

for env in "${ENVIRONMENTS[@]}"; do
    echo "🌍 Updating environment: $env"
    
    case "$env" in
        "development")
            # Development: Force update with verbose output
            "$UPDATER_PATH" --force --verbose
            ;;
        "staging")
            # Staging: Normal update with backup
            "$UPDATER_PATH" --verbose
            ;;
        "production")
            # Production: Dry run only for safety
            "$UPDATER_PATH" --dry-run --verbose
            echo "⚠️  Production requires manual approval"
            ;;
    esac
    
    echo "✅ Environment $env processed"
    echo ""
done
EOF

echo ""

# Example 6: Integration with CI/CD
echo "Example 6: CI/CD Integration"
echo "----------------------------"
cat << 'EOF'
#!/bin/bash
# CI/CD pipeline integration

# Environment variables for CI
export CI=true
export DEBIAN_FRONTEND=noninteractive

# Pre-update checks
echo "🔍 Pre-update system checks"
df -h                    # Disk space
free -h                  # Memory
which curl git          # Required tools

# Update with CI-friendly options
if [[ "${CI:-}" == "true" ]]; then
    echo "🤖 Running in CI environment"
    ./vscode_ultimate_updater.sh --force --skip-backup --verbose
else
    echo "👤 Running in interactive environment"
    ./vscode_ultimate_updater.sh --dry-run
    read -p "Proceed with update? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        ./vscode_ultimate_updater.sh --verbose
    fi
fi

# Post-update verification
echo "✅ Verifying update"
code-insiders --version
EOF

echo ""

# Example 7: Custom settings override
echo "Example 7: Custom settings override"
echo "-----------------------------------"
cat << 'EOF'
#!/bin/bash
# Apply custom settings after update

SETTINGS_FILE="$HOME/.config/Code - Insiders/User/settings.json"
CUSTOM_SETTINGS='{
    "workbench.colorTheme": "Dark+ (default dark)",
    "editor.fontSize": 14,
    "editor.fontFamily": "Fira Code",
    "editor.fontLigatures": true,
    "terminal.integrated.fontSize": 12
}'

# Run update first
./vscode_ultimate_updater.sh

# Apply custom settings
echo "🎨 Applying custom settings"
python3 << PYTHON_EOF
import json

# Read current settings
try:
    with open('$SETTINGS_FILE', 'r') as f:
        settings = json.load(f)
except:
    settings = {}

# Merge custom settings
custom = $CUSTOM_SETTINGS
settings.update(custom)

# Write back
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=4)

print("✅ Custom settings applied")
PYTHON_EOF
EOF

echo ""

# Example 8: Rollback capability
echo "Example 8: Rollback capability"
echo "------------------------------"
cat << 'EOF'
#!/bin/bash
# Update with rollback capability

BACKUP_MARKER="$HOME/.last_vscode_backup"

echo "🔄 Starting update with rollback capability"

# Run update
if ./vscode_ultimate_updater.sh --verbose; then
    echo "✅ Update completed successfully"
    
    # Test VSCode functionality
    echo "🧪 Testing VSCode functionality"
    if timeout 30 code-insiders --version >/dev/null 2>&1; then
        echo "✅ VSCode is working correctly"
    else
        echo "❌ VSCode test failed, initiating rollback"
        
        # Rollback procedure
        if [[ -f "$BACKUP_MARKER" ]]; then
            BACKUP_PATH=$(cat "$BACKUP_MARKER")
            echo "🔄 Rolling back from: $BACKUP_PATH"
            
            # Restore settings
            cp "$BACKUP_PATH/settings/"* "$HOME/.config/Code - Insiders/User/"
            
            echo "✅ Rollback completed"
        else
            echo "❌ No backup found for rollback"
        fi
    fi
else
    echo "❌ Update failed"
    exit 1
fi
EOF

echo ""
echo "================================================="
echo "Advanced examples for power users and automation"
echo "Customize these scripts for your specific needs"
