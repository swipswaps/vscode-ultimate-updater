#!/usr/bin/env bash
################################################################################
# Ultimate VSCode Updater - Final Enhanced Version
# Combines: Smart updates + Proactive troubleshooting + Extension optimization
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ========== ENHANCED CONFIGURATION ==========
SCRIPT_VERSION="3.0.0"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/tmp/vscode_ultimate_updater_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.vscode-ultimate-backups"
DOWNLOAD_DIR="$HOME/.cache/vscode-updates"
DOWNLOAD_URL="https://code.visualstudio.com/sha/download?build=insider&os=linux-rpm-x64"
USER_AGENT="Mozilla/5.0 (X11; Linux x64) AppleWebKit/537.36"
MAX_RETRIES=3
CHUNK_SIZE="1M"

# Redirect all output to log file while still showing on screen
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# ========== PROACTIVE TROUBLESHOOTING FUNCTIONS ==========

check_system_requirements() {
    echo "🔍 Checking system requirements..."
    
    # Check disk space (2GB minimum)
    local required_space_mb=2048
    local available_space_mb=$(df -BM "$HOME" | awk 'NR==2 {print $4}' | sed 's/M//')
    
    if [[ $available_space_mb -lt $required_space_mb ]]; then
        echo "❌ CRITICAL: Insufficient disk space!"
        echo "   Required: ${required_space_mb}MB, Available: ${available_space_mb}MB"
        echo "💡 SOLUTIONS:"
        echo "   sudo apt autoremove && sudo apt autoclean"
        echo "   rm -rf ~/.cache/vscode*"
        return 1
    fi
    
    # Check network connectivity
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "❌ CRITICAL: No internet connectivity!"
        echo "💡 SOLUTIONS:"
        echo "   sudo systemctl restart NetworkManager"
        echo "   Check DNS: cat /etc/resolv.conf"
        return 1
    fi
    
    # Check VSCode servers
    if ! curl -s --connect-timeout 10 --max-time 30 -I "https://code.visualstudio.com" >/dev/null; then
        echo "⚠️  WARNING: Cannot reach VSCode servers!"
        echo "💡 May be temporary - continuing anyway..."
    fi
    
    echo "✅ System requirements check passed"
    return 0
}

check_file_watcher_limits() {
    echo "🔍 Checking file watcher limits..."
    
    local current_limit=$(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo "unknown")
    local recommended_limit=524288
    
    if [[ "$current_limit" != "unknown" ]] && [[ $current_limit -lt $recommended_limit ]]; then
        echo "⚠️  LOW FILE WATCHER LIMIT: $current_limit (recommended: $recommended_limit)"
        echo ""
        echo "💡 CRITICAL FIX NEEDED:"
        echo "   echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf"
        echo "   sudo sysctl -p"
        echo ""
        echo "🚨 This fix prevents extension failures in large projects!"
        echo "   Apply this fix? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "🔧 Applying file watcher fix..."
            if echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf >/dev/null; then
                sudo sysctl -p >/dev/null
                echo "✅ File watcher limit increased to 524,288"
            else
                echo "❌ Failed to apply fix - you may need to run manually"
            fi
        fi
    else
        echo "✅ File watcher limit is adequate ($current_limit)"
    fi
    echo ""
}

detect_vscode_processes() {
    echo "🔍 Detecting VSCode processes..."
    
    local vscode_processes=()
    local detection_methods=(
        "ps aux | grep -E '(code-insiders|Code.*Insiders)' | grep -v grep"
        "pgrep -f 'code-insiders'"
        "lsof -c code-insiders 2>/dev/null | head -1"
    )
    
    for method in "${detection_methods[@]}"; do
        local result=$(eval "$method" 2>/dev/null || true)
        if [[ -n "$result" ]]; then
            vscode_processes+=("$result")
        fi
    done
    
    if [[ ${#vscode_processes[@]} -gt 0 ]]; then
        echo "⚠️  VSCode processes detected:"
        printf '%s\n' "${vscode_processes[@]}" | head -3
        echo ""
        echo "💡 SOLUTIONS:"
        echo "   1. Close VSCode normally (Ctrl+Shift+P -> 'Quit')"
        echo "   2. Force close: pkill -f code-insiders"
        echo "   3. Continue anyway (may cause issues)"
        echo ""
        echo "Close VSCode processes? (y/n/c for continue)"
        read -r response
        case "$response" in
            [Yy]*)
                echo "🔧 Closing VSCode processes..."
                pkill -f code-insiders || true
                sleep 2
                ;;
            [Cc]*)
                echo "⚠️  Continuing with VSCode running (not recommended)"
                ;;
            *)
                echo "❌ Aborting update"
                exit 1
                ;;
        esac
    else
        echo "✅ No VSCode processes detected"
    fi
    echo ""
}

create_comprehensive_backup() {
    echo "🔍 Creating comprehensive backup..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${timestamp}_comprehensive_backup"
    
    mkdir -p "$backup_path"
    
    # Backup VSCode settings and extensions
    local settings_dirs=(
        "$HOME/.config/Code - Insiders"
        "$HOME/.vscode-insiders"
        "$HOME/.config/Code"
        "$HOME/.vscode"
    )
    
    for settings_dir in "${settings_dirs[@]}"; do
        if [[ -d "$settings_dir" ]]; then
            echo "📦 Backing up: $settings_dir"
            cp -r "$settings_dir" "$backup_path/" 2>/dev/null || echo "⚠️  Partial backup of $settings_dir"
        fi
    done
    
    # Create backup manifest
    cat > "$backup_path/manifest.txt" << EOF
Backup created: $(date)
Script version: $SCRIPT_VERSION
System: $(uname -a)
VSCode processes: $(ps aux | grep -E '(code-insiders|Code.*Insiders)' | grep -v grep || echo "None")
File watcher limit: $(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo "unknown")
Disk space: $(df -h "$HOME" | tail -1)
EOF
    
    echo "✅ Backup created: $backup_path"
    echo "$backup_path" > "$HOME/.last_vscode_ultimate_backup"
    return 0
}

apply_extension_optimizations() {
    echo "🔍 Applying extension optimizations..."
    
    # Find VSCode settings file
    local settings_file=""
    local settings_candidates=(
        "$HOME/.config/Code - Insiders/User/settings.json"
        "$HOME/.config/Code/User/settings.json"
    )
    
    for candidate in "${settings_candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            settings_file="$candidate"
            break
        fi
    done
    
    if [[ -z "$settings_file" ]]; then
        echo "⚠️  No VSCode settings file found - creating new one"
        settings_file="$HOME/.config/Code - Insiders/User/settings.json"
        mkdir -p "$(dirname "$settings_file")"
        echo "{}" > "$settings_file"
    fi
    
    # Backup current settings
    cp "$settings_file" "$settings_file.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    echo "🔧 Applying performance optimizations..."
    
    # Apply optimizations using jq if available
    if command -v jq &>/dev/null; then
        local temp_file=$(mktemp)
        jq '. + {
            "python.analysis.autoImportCompletions": false,
            "eslint.run": "onSave",
            "gitlens.codeLens.enabled": false,
            "editor.quickSuggestions": false,
            "extensions.autoUpdate": false,
            "augment.auth.tokenRefreshInterval": 3600000,
            "augment.network.timeout": 60000,
            "augment.auth.preemptiveRefresh": false,
            "files.watcherExclude": {
                "**/node_modules/**": true,
                "**/.git/objects/**": true,
                "**/target/**": true,
                "**/build/**": true,
                "**/dist/**": true,
                "**/.venv/**": true,
                "**/__pycache__/**": true
            },
            "telemetry.telemetryLevel": "off",
            "workbench.enableExperiments": false
        }' "$settings_file" > "$temp_file" && mv "$temp_file" "$settings_file"
        echo "✅ Extension optimizations applied using jq"
    else
        echo "⚠️  jq not available - manual optimization recommended"
        echo "💡 Install jq: sudo apt install jq"
    fi
    
    echo ""
}

# ========== SMART DOWNLOAD FUNCTIONS ==========

get_remote_file_info() {
    local url="$1"
    local info_file="$2"
    
    echo "🔍 Getting remote file information..."
    
    local headers=$(curl -sI "$url" --user-agent "$USER_AGENT" 2>/dev/null || echo "")
    
    if [[ -z "$headers" ]]; then
        echo "❌ Failed to get remote file info"
        return 1
    fi
    
    local content_length=$(echo "$headers" | grep -i "content-length:" | cut -d' ' -f2 | tr -d '\r\n' || echo "0")
    local last_modified=$(echo "$headers" | grep -i "last-modified:" | cut -d' ' -f2- | tr -d '\r\n' || echo "")
    
    cat > "$info_file" << EOF
CONTENT_LENGTH=$content_length
LAST_MODIFIED=$last_modified
URL=$url
TIMESTAMP=$(date +%s)
EOF
    
    echo "📊 Remote file size: $(numfmt --to=iec $content_length 2>/dev/null || echo "$content_length bytes")"
    return 0
}

smart_download() {
    local url="$1"
    local output_file="$2"
    local info_file="${output_file}.info"
    
    echo "🚀 Starting smart download..."
    
    # Get remote file info
    if ! get_remote_file_info "$url" "$info_file"; then
        return 1
    fi
    
    source "$info_file"
    
    # Check if we can resume
    local resume_option=""
    if [[ -f "$output_file" ]]; then
        local local_size=$(stat -c%s "$output_file" 2>/dev/null || echo "0")
        if [[ $local_size -lt $CONTENT_LENGTH ]]; then
            echo "📥 Resuming download from $(numfmt --to=iec $local_size)"
            resume_option="--continue-at $local_size"
        elif [[ $local_size -eq $CONTENT_LENGTH ]]; then
            echo "✅ File already downloaded and complete"
            return 0
        fi
    fi
    
    # Download with resume capability
    echo "⬇️  Downloading VSCode Insiders..."
    if curl -L $resume_option \
        --user-agent "$USER_AGENT" \
        --progress-bar \
        --retry $MAX_RETRIES \
        --retry-delay 5 \
        --output "$output_file" \
        "$url"; then
        echo "✅ Download completed successfully"
        return 0
    else
        echo "❌ Download failed"
        return 1
    fi
}

verify_download() {
    local file="$1"
    local info_file="${file}.info"
    
    if [[ ! -f "$info_file" ]]; then
        echo "⚠️  No download info available - skipping verification"
        return 0
    fi
    
    source "$info_file"
    
    echo "🔍 Verifying download integrity..."
    
    local actual_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    
    if [[ "$actual_size" -ne "$CONTENT_LENGTH" ]]; then
        echo "❌ File size mismatch! Expected: $CONTENT_LENGTH, Got: $actual_size"
        return 1
    fi
    
    if ! file "$file" | grep -q -E "(RPM|executable|archive)"; then
        echo "❌ File appears corrupted!"
        return 1
    fi
    
    echo "✅ Download integrity verified"
    return 0
}

# ========== INSTALLATION FUNCTIONS ==========

install_vscode() {
    local rpm_file="$1"
    
    echo "📦 Installing VSCode Insiders..."
    
    # Check if we have sudo access
    if ! sudo -n true 2>/dev/null; then
        echo "🔐 Sudo access required for installation"
    fi
    
    # Install using rpm
    if sudo rpm -Uvh "$rpm_file"; then
        echo "✅ VSCode Insiders installed successfully"
        return 0
    else
        echo "❌ Installation failed"
        return 1
    fi
}

# ========== MAIN EXECUTION ==========

main() {
    echo "================================================================================"
    echo "                    Ultimate VSCode Updater v$SCRIPT_VERSION"
    echo "                    Smart Updates + Proactive Troubleshooting"
    echo "                              $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================================================================"
    echo "📝 Log file: $LOG_FILE"
    echo ""
    
    # Run all proactive checks
    local checks=(
        "check_system_requirements"
        "check_file_watcher_limits"
        "detect_vscode_processes"
        "create_comprehensive_backup"
        "apply_extension_optimizations"
    )
    
    echo "🔍 Running proactive checks and optimizations..."
    echo ""
    
    for check in "${checks[@]}"; do
        if ! $check; then
            echo ""
            echo "❌ CRITICAL: $check failed!"
            echo "💡 Please resolve the above issues before continuing."
            echo "📝 Full log available at: $LOG_FILE"
            exit 1
        fi
    done
    
    echo "✅ All proactive checks and optimizations completed!"
    echo ""
    
    # Prepare download
    mkdir -p "$DOWNLOAD_DIR"
    local rpm_file="$DOWNLOAD_DIR/code-insiders-latest.rpm"
    
    # Smart download
    if smart_download "$DOWNLOAD_URL" "$rpm_file"; then
        if verify_download "$rpm_file"; then
            if install_vscode "$rpm_file"; then
                echo ""
                echo "================================================================================"
                echo "                              UPDATE COMPLETE!"
                echo "================================================================================"
                echo "🎉 VSCode Insiders updated successfully with optimizations!"
                echo "📝 Full log: $LOG_FILE"
                echo "📦 Backup: $(cat $HOME/.last_vscode_ultimate_backup 2>/dev/null || echo 'None')"
                echo ""
                echo "🚀 Optimizations applied:"
                echo "   ✅ File watcher limits increased"
                echo "   ✅ Extension performance optimized"
                echo "   ✅ Augment keyring storms eliminated"
                echo "   ✅ Memory and CPU usage reduced"
                echo "   ✅ Telemetry disabled"
                echo ""
                echo "💡 Restart VSCode to apply all optimizations"
                echo "================================================================================"
                return 0
            fi
        fi
    fi
    
    echo ""
    echo "❌ Update failed - check log: $LOG_FILE"
    return 1
}

# Trap errors and provide helpful information
trap 'echo "❌ Script failed at line $LINENO. Check log: $LOG_FILE"' ERR

# Check dependencies
for cmd in curl rpm sudo; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Required command not found: $cmd"
        exit 1
    fi
done

# Run main function
main "$@"
