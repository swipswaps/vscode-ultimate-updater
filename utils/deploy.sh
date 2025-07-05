#!/bin/bash
################################################################################
# Deployment Utility for VSCode Ultimate Updater
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
UPDATER_SCRIPT="$REPO_ROOT/vscode_ultimate_updater.sh"

# Default deployment locations
DEFAULT_SYSTEM_PATH="/usr/local/bin/vscode-update"
DEFAULT_USER_PATH="$HOME/.local/bin/vscode-update"

show_help() {
    cat << EOF
VSCode Ultimate Updater Deployment Utility

USAGE:
    $0 [OPTIONS] [TARGET]

OPTIONS:
    --system, -s        Install system-wide (requires sudo)
    --user, -u          Install for current user only
    --local, -l         Create local symlink in current directory
    --uninstall         Remove installed version
    --help, -h          Show this help

TARGETS:
    system              Install to $DEFAULT_SYSTEM_PATH
    user                Install to $DEFAULT_USER_PATH
    PATH                Install to custom path

EXAMPLES:
    $0 --system                    # Install system-wide
    $0 --user                      # Install for current user
    $0 --local                     # Create local symlink
    $0 /custom/path/vscode-update  # Install to custom path
    $0 --uninstall                 # Remove installation

EOF
}

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

verify_script() {
    if [[ ! -f "$UPDATER_SCRIPT" ]]; then
        echo "❌ Updater script not found: $UPDATER_SCRIPT"
        exit 1
    fi
    
    if [[ ! -x "$UPDATER_SCRIPT" ]]; then
        echo "❌ Updater script not executable: $UPDATER_SCRIPT"
        exit 1
    fi
    
    log "✅ Updater script verified: $UPDATER_SCRIPT"
}

test_installation() {
    local install_path="$1"
    
    log "🧪 Testing installation..."
    
    if [[ -f "$install_path" ]] && [[ -x "$install_path" ]]; then
        if "$install_path" --help >/dev/null 2>&1; then
            log "✅ Installation test passed"
            return 0
        else
            log "❌ Installation test failed - script doesn't work"
            return 1
        fi
    else
        log "❌ Installation test failed - file not found or not executable"
        return 1
    fi
}

install_system() {
    local target_path="${1:-$DEFAULT_SYSTEM_PATH}"
    
    log "🚀 Installing system-wide to: $target_path"
    
    # Check if we have sudo access
    if ! sudo -v; then
        echo "❌ Sudo access required for system installation"
        exit 1
    fi
    
    # Create directory if needed
    sudo mkdir -p "$(dirname "$target_path")"
    
    # Copy script
    sudo cp "$UPDATER_SCRIPT" "$target_path"
    sudo chmod +x "$target_path"
    
    # Test installation
    if test_installation "$target_path"; then
        log "✅ System installation completed: $target_path"
        log "💡 You can now run: $(basename "$target_path") --help"
    else
        log "❌ System installation failed"
        exit 1
    fi
}

install_user() {
    local target_path="${1:-$DEFAULT_USER_PATH}"
    
    log "👤 Installing for current user to: $target_path"
    
    # Create directory if needed
    mkdir -p "$(dirname "$target_path")"
    
    # Copy script
    cp "$UPDATER_SCRIPT" "$target_path"
    chmod +x "$target_path"
    
    # Add to PATH if not already there
    local bin_dir="$(dirname "$target_path")"
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        log "💡 Adding $bin_dir to PATH in ~/.bashrc"
        echo "export PATH=\"$bin_dir:\$PATH\"" >> ~/.bashrc
        log "💡 Run 'source ~/.bashrc' or restart your terminal"
    fi
    
    # Test installation
    if test_installation "$target_path"; then
        log "✅ User installation completed: $target_path"
        log "💡 You can now run: $(basename "$target_path") --help"
    else
        log "❌ User installation failed"
        exit 1
    fi
}

install_local() {
    local target_path="./vscode-update"
    
    log "📁 Creating local symlink: $target_path"
    
    # Create symlink
    ln -sf "$UPDATER_SCRIPT" "$target_path"
    
    # Test installation
    if test_installation "$target_path"; then
        log "✅ Local symlink created: $target_path"
        log "💡 You can now run: $target_path --help"
    else
        log "❌ Local symlink creation failed"
        exit 1
    fi
}

uninstall() {
    log "🗑️  Uninstalling VSCode Ultimate Updater..."
    
    local locations=(
        "$DEFAULT_SYSTEM_PATH"
        "$DEFAULT_USER_PATH"
        "./vscode-update"
    )
    
    local removed_count=0
    
    for location in "${locations[@]}"; do
        if [[ -f "$location" ]] || [[ -L "$location" ]]; then
            log "🗑️  Removing: $location"
            
            if [[ "$location" == "$DEFAULT_SYSTEM_PATH" ]]; then
                sudo rm -f "$location"
            else
                rm -f "$location"
            fi
            
            ((removed_count++))
        fi
    done
    
    if [[ $removed_count -gt 0 ]]; then
        log "✅ Uninstallation completed ($removed_count files removed)"
    else
        log "ℹ️  No installations found to remove"
    fi
}

main() {
    echo "================================================================================"
    echo "                    VSCode Ultimate Updater Deployment"
    echo "                              $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================================================================"
    
    # Verify script exists
    verify_script
    
    # Parse arguments
    local install_type=""
    local custom_path=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --system|-s)
                install_type="system"
                shift
                ;;
            --user|-u)
                install_type="user"
                shift
                ;;
            --local|-l)
                install_type="local"
                shift
                ;;
            --uninstall)
                uninstall
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            system)
                install_type="system"
                shift
                ;;
            user)
                install_type="user"
                shift
                ;;
            local)
                install_type="local"
                shift
                ;;
            /*)
                # Absolute path
                custom_path="$1"
                install_type="custom"
                shift
                ;;
            *)
                echo "❌ Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Default to user installation if no type specified
    if [[ -z "$install_type" ]]; then
        install_type="user"
    fi
    
    # Perform installation
    case "$install_type" in
        "system")
            install_system "$custom_path"
            ;;
        "user")
            install_user "$custom_path"
            ;;
        "local")
            install_local
            ;;
        "custom")
            if [[ -z "$custom_path" ]]; then
                echo "❌ Custom path not specified"
                exit 1
            fi
            
            # Determine if custom path needs sudo
            if [[ "$custom_path" == /usr/* ]] || [[ "$custom_path" == /opt/* ]]; then
                install_system "$custom_path"
            else
                install_user "$custom_path"
            fi
            ;;
        *)
            echo "❌ Unknown installation type: $install_type"
            exit 1
            ;;
    esac
    
    echo ""
    echo "================================================================================"
    echo "                           DEPLOYMENT COMPLETE"
    echo "================================================================================"
    echo ""
    echo "🎉 VSCode Ultimate Updater deployed successfully!"
    echo ""
    echo "📖 Next steps:"
    echo "   1. Test the installation: $(basename "${custom_path:-$DEFAULT_USER_PATH}") --help"
    echo "   2. Run a dry run test: $(basename "${custom_path:-$DEFAULT_USER_PATH}") --dry-run"
    echo "   3. Perform your first update: $(basename "${custom_path:-$DEFAULT_USER_PATH}")"
    echo ""
    echo "📚 Documentation:"
    echo "   • Installation: $REPO_ROOT/docs/INSTALLATION.md"
    echo "   • Usage Guide: $REPO_ROOT/docs/USAGE.md"
    echo "   • Troubleshooting: $REPO_ROOT/docs/TROUBLESHOOTING.md"
    echo ""
    echo "================================================================================"
}

# Run main function
main "$@"
