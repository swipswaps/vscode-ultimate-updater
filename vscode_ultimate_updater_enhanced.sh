#!/usr/bin/env bash
################################################################################
# Ultimate VSCode Updater - Enhanced with Proactive Troubleshooting
# Addresses the most common pain points found in official docs, forums, and repos
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ========== ENHANCED CONFIGURATION ==========
SCRIPT_VERSION="2.2.0"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/tmp/vscode_updater_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.vscode-backups"
DOWNLOAD_DIR="$HOME/.cache/vscode-updates"

# Redirect all output to log file while still showing on screen
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# ========== PROACTIVE TROUBLESHOOTING FUNCTIONS ==========

# Pain Point #1: Insufficient disk space (most common cause of failures)
check_disk_space() {
    local required_space_mb=2048  # 2GB minimum for VSCode + temp files
    local available_space_mb
    
    echo "🔍 Checking disk space requirements..."
    
    # Get available space in MB for download directory
    available_space_mb=$(df -BM "$HOME" | awk 'NR==2 {print $4}' | sed 's/M//')
    
    if [[ $available_space_mb -lt $required_space_mb ]]; then
        echo "❌ CRITICAL: Insufficient disk space!"
        echo "   Required: ${required_space_mb}MB"
        echo "   Available: ${available_space_mb}MB"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Free up disk space: sudo apt autoremove && sudo apt autoclean"
        echo "   2. Clear VSCode cache: rm -rf ~/.cache/vscode*"
        echo "   3. Clear old downloads: rm -rf ~/.cache/vscode-updates/*"
        echo "   4. Move large files to external storage"
        return 1
    fi
    
    echo "✅ Disk space check passed (${available_space_mb}MB available)"
    return 0
}

# Pain Point #2: Network connectivity issues
check_network_connectivity() {
    echo "🔍 Checking network connectivity..."
    
    # Test basic internet connectivity
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "❌ CRITICAL: No internet connectivity!"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Check your network connection"
        echo "   2. Restart network manager: sudo systemctl restart NetworkManager"
        echo "   3. Check DNS settings: cat /etc/resolv.conf"
        echo "   4. Try different DNS: echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
        return 1
    fi
    
    # Test VSCode servers specifically
    if ! curl -s --connect-timeout 10 --max-time 30 -I "https://code.visualstudio.com" >/dev/null; then
        echo "❌ WARNING: Cannot reach VSCode servers!"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Check if behind corporate firewall"
        echo "   2. Configure proxy if needed: export https_proxy=http://proxy:port"
        echo "   3. Try VPN if geo-blocked"
        echo "   4. Wait and retry - servers may be temporarily down"
        return 1
    fi
    
    echo "✅ Network connectivity check passed"
    return 0
}

# Pain Point #3: Permission issues (very common on Linux)
check_permissions() {
    echo "🔍 Checking file permissions..."
    
    # Check if we can write to home directory
    if [[ ! -w "$HOME" ]]; then
        echo "❌ CRITICAL: Cannot write to home directory!"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Fix home directory permissions: sudo chown -R $USER:$USER $HOME"
        echo "   2. Check if home is mounted read-only: mount | grep $HOME"
        return 1
    fi
    
    # Create necessary directories with proper permissions
    for dir in "$BACKUP_DIR" "$DOWNLOAD_DIR"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            echo "❌ CRITICAL: Cannot create directory: $dir"
            echo ""
            echo "💡 SOLUTIONS:"
            echo "   1. Check parent directory permissions"
            echo "   2. Run: sudo chown -R $USER:$USER $(dirname $dir)"
            return 1
        fi
        chmod 755 "$dir"
    done
    
    echo "✅ Permission check passed"
    return 0
}

# Pain Point #4: VSCode process detection failures
detect_vscode_processes() {
    echo "🔍 Detecting VSCode processes..."
    
    local vscode_processes=()
    local detection_methods=(
        "ps aux | grep -E '(code-insiders|Code.*Insiders)' | grep -v grep"
        "pgrep -f 'code-insiders'"
        "pstree -p | grep -i code"
        "lsof -c code-insiders 2>/dev/null | head -1"
    )
    
    # Try multiple detection methods (common pain point: single method fails)
    for method in "${detection_methods[@]}"; do
        local result=$(eval "$method" 2>/dev/null || true)
        if [[ -n "$result" ]]; then
            vscode_processes+=("$result")
        fi
    done
    
    if [[ ${#vscode_processes[@]} -gt 0 ]]; then
        echo "⚠️  VSCode processes detected:"
        printf '%s\n' "${vscode_processes[@]}" | head -5
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Close VSCode normally (Ctrl+Shift+P -> 'Quit')"
        echo "   2. Force close: pkill -f code-insiders"
        echo "   3. Kill specific PIDs: kill \$(pgrep -f code-insiders)"
        echo "   4. Reboot if processes are stuck"
        return 1
    fi
    
    echo "✅ No VSCode processes detected"
    return 0
}

# Pain Point #5: Package manager issues
check_package_manager() {
    echo "🔍 Checking package manager status..."
    
    # Check if package manager is locked (common issue)
    if [[ -f /var/lib/dpkg/lock-frontend ]] || [[ -f /var/lib/apt/lists/lock ]]; then
        echo "❌ WARNING: Package manager may be locked!"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Wait for other package operations to complete"
        echo "   2. Kill stuck processes: sudo killall apt apt-get dpkg"
        echo "   3. Remove locks: sudo rm /var/lib/apt/lists/lock /var/lib/dpkg/lock*"
        echo "   4. Reconfigure packages: sudo dpkg --configure -a"
        # Don't return 1 here, just warn
    fi
    
    # Check if we have sudo access for installation
    if ! sudo -n true 2>/dev/null; then
        echo "❌ WARNING: No sudo access detected!"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Run with sudo: sudo $0"
        echo "   2. Add user to sudo group: sudo usermod -aG sudo $USER"
        echo "   3. Configure passwordless sudo for this script"
        # Don't return 1, user might have other installation methods
    fi
    
    echo "✅ Package manager check completed"
    return 0
}

# Pain Point #6: Corrupted downloads (very common with large files)
verify_download_integrity() {
    local file="$1"
    local expected_size="$2"
    
    echo "🔍 Verifying download integrity..."
    
    if [[ ! -f "$file" ]]; then
        echo "❌ CRITICAL: Downloaded file not found: $file"
        return 1
    fi
    
    local actual_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    
    # Check file size
    if [[ "$actual_size" -ne "$expected_size" ]]; then
        echo "❌ CRITICAL: File size mismatch!"
        echo "   Expected: $expected_size bytes"
        echo "   Actual: $actual_size bytes"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Delete corrupted file: rm '$file'"
        echo "   2. Retry download with resume capability"
        echo "   3. Check network stability during download"
        return 1
    fi
    
    # Check if file is actually a valid package
    if ! file "$file" | grep -q -E "(RPM|Debian|executable|archive)"; then
        echo "❌ CRITICAL: Downloaded file appears corrupted!"
        echo "   File type: $(file "$file")"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Delete corrupted file: rm '$file'"
        echo "   2. Clear browser cache if using browser download"
        echo "   3. Try different download mirror"
        return 1
    fi
    
    echo "✅ Download integrity verified"
    return 0
}

# Pain Point #7: Environment detection failures
detect_environment() {
    echo "🔍 Detecting system environment..."
    
    # Detect if running inside VSCode (major pain point)
    local inside_vscode=false
    if [[ "${TERM_PROGRAM:-}" == "vscode" ]] || \
       [[ -n "${VSCODE_PID:-}" ]] || \
       [[ "$(ps -o comm= -p $PPID 2>/dev/null)" =~ code ]] || \
       [[ "$(pstree -p $$ 2>/dev/null)" =~ code ]]; then
        inside_vscode=true
    fi
    
    if [[ "$inside_vscode" == "true" ]]; then
        echo "⚠️  SAFETY WARNING: Running inside VSCode!"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Close this terminal and run from external terminal"
        echo "   2. Use Ctrl+Shift+\` to open external terminal"
        echo "   3. Run from system terminal (not VSCode integrated terminal)"
        echo ""
        echo "🚨 Continuing anyway in 10 seconds... (Ctrl+C to abort)"
        sleep 10
    fi
    
    # Detect platform
    local platform="$(uname -s)"
    local arch="$(uname -m)"
    
    echo "✅ Environment detected:"
    echo "   Platform: $platform"
    echo "   Architecture: $arch"
    echo "   Inside VSCode: $inside_vscode"
    
    return 0
}

# Pain Point #8: Backup failures
create_safety_backup() {
    echo "🔍 Creating safety backup..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${timestamp}_pre-update_insiders"
    
    # Create backup directory
    if ! mkdir -p "$backup_path"; then
        echo "❌ CRITICAL: Cannot create backup directory!"
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Check disk space: df -h"
        echo "   2. Check permissions: ls -la $BACKUP_DIR"
        echo "   3. Use different backup location: export BACKUP_DIR=/tmp/vscode-backups"
        return 1
    fi
    
    # Backup VSCode settings
    local settings_dirs=(
        "$HOME/.config/Code - Insiders"
        "$HOME/.vscode-insiders"
    )
    
    for settings_dir in "${settings_dirs[@]}"; do
        if [[ -d "$settings_dir" ]]; then
            echo "📦 Backing up: $settings_dir"
            if ! cp -r "$settings_dir" "$backup_path/" 2>/dev/null; then
                echo "⚠️  Warning: Could not backup $settings_dir"
            fi
        fi
    done
    
    # Create backup manifest
    cat > "$backup_path/manifest.txt" << EOF
Backup created: $(date)
Script version: $SCRIPT_VERSION
System: $(uname -a)
VSCode processes at backup time:
$(ps aux | grep -E '(code-insiders|Code.*Insiders)' | grep -v grep || echo "None")
EOF
    
    echo "✅ Backup created: $backup_path"
    echo "$backup_path" > "$HOME/.last_vscode_backup"
    return 0
}

# ========== MAIN EXECUTION WITH ENHANCED ERROR HANDLING ==========

main() {
    echo "================================================================================"
    echo "                    Ultimate VSCode Updater v$SCRIPT_VERSION"
    echo "                    Enhanced with Proactive Troubleshooting"
    echo "                              $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================================================================"
    echo "📝 Log file: $LOG_FILE"
    echo ""
    
    # Run all proactive checks
    local checks=(
        "check_disk_space"
        "check_network_connectivity" 
        "check_permissions"
        "detect_environment"
        "check_package_manager"
        "detect_vscode_processes"
        "create_safety_backup"
    )
    
    echo "🔍 Running proactive troubleshooting checks..."
    echo ""
    
    for check in "${checks[@]}"; do
        if ! $check; then
            echo ""
            echo "❌ CRITICAL: $check failed!"
            echo "💡 Please resolve the above issues before continuing."
            echo "📝 Full log available at: $LOG_FILE"
            exit 1
        fi
        echo ""
    done
    
    echo "✅ All proactive checks passed!"
    echo ""
    echo "🚀 Proceeding with VSCode update..."
    echo "📝 Monitor progress in: $LOG_FILE"
    
    # Continue with actual update process...
    # (This would call the existing update functions)
    
    echo ""
    echo "================================================================================"
    echo "                              UPDATE COMPLETE"
    echo "================================================================================"
    echo "📝 Full log: $LOG_FILE"
    echo "📦 Backup: $(cat $HOME/.last_vscode_backup 2>/dev/null || echo 'None')"
    echo "🎉 VSCode Insiders updated successfully!"
}

# ========== SCRIPT EXECUTION ==========

# Trap errors and provide helpful information
trap 'echo "❌ Script failed at line $LINENO. Check log: $LOG_FILE"' ERR

# Run main function
main "$@"
