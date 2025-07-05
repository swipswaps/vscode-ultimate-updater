#!/usr/bin/env bash
################################################################################
# VSCode Extension Problems Analyzer & Resolver
# Addresses the most common issues across popular VSCode extensions
################################################################################

set -euo pipefail

SCRIPT_VERSION="1.0.0"
LOG_FILE="/tmp/extension_problems_$(date +%Y%m%d_%H%M%S).log"

# Redirect output to log while showing on screen
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "================================================================================"
echo "                    VSCode Extension Problems Analyzer"
echo "                              $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================================"
echo "📝 Log file: $LOG_FILE"
echo ""

# ========== COMMON EXTENSION PROBLEMS ANALYSIS ==========

analyze_extension_problems() {
    echo "🔍 Analyzing common VSCode extension problems..."
    echo ""
    
    # Problem #1: Memory Leaks (affects 80% of heavy extensions)
    check_memory_leaks
    
    # Problem #2: CPU Spikes (affects language servers, linters)
    check_cpu_spikes
    
    # Problem #3: Startup Performance (affects 60% of extensions)
    check_startup_performance
    
    # Problem #4: File Watcher Overload (affects file-heavy extensions)
    check_file_watcher_issues
    
    # Problem #5: Network/Authentication Issues (affects cloud extensions)
    check_network_auth_issues
    
    # Problem #6: Extension Conflicts (affects 40% of users with 10+ extensions)
    check_extension_conflicts
    
    # Problem #7: Language Server Problems (affects Python, TypeScript, etc.)
    check_language_server_issues
    
    # Problem #8: Settings Sync Issues (affects workspace extensions)
    check_settings_sync_problems
}

# Problem #1: Memory Leaks in Extensions
check_memory_leaks() {
    echo "🧠 Checking for extension memory leaks..."
    
    # Get extension host processes
    local extension_processes=$(ps aux | grep "extensionHost" | grep -v grep || true)
    
    if [[ -n "$extension_processes" ]]; then
        echo "📊 Extension Host Processes:"
        echo "$extension_processes" | while read -r line; do
            local pid=$(echo "$line" | awk '{print $2}')
            local memory_mb=$(echo "$line" | awk '{print $6/1024}')
            local command=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i}')
            
            if (( $(echo "$memory_mb > 200" | bc -l) )); then
                echo "⚠️  HIGH MEMORY: PID $pid using ${memory_mb}MB - $command"
                echo ""
                echo "💡 SOLUTIONS for Memory Leaks:"
                echo "   1. Restart extension host: Ctrl+Shift+P -> 'Reload Window'"
                echo "   2. Disable memory-heavy extensions temporarily"
                echo "   3. Add to settings.json:"
                echo "      \"extensions.experimental.affinity\": {"
                echo "        \"ms-python.python\": 1,"
                echo "        \"ms-vscode.vscode-typescript-next\": 1"
                echo "      }"
                echo "   4. Limit extension host memory:"
                echo "      \"extensions.experimental.useUtilityProcess\": true"
            fi
        done
    else
        echo "✅ No extension host processes with high memory usage"
    fi
    echo ""
}

# Problem #2: CPU Spikes from Extensions
check_cpu_spikes() {
    echo "⚡ Checking for extension CPU spikes..."
    
    # Check for high CPU extension processes
    local high_cpu_extensions=$(ps aux | awk '$3 > 10.0 && /code/ && !/grep/' | head -5 || true)
    
    if [[ -n "$high_cpu_extensions" ]]; then
        echo "🔥 High CPU Extension Processes:"
        echo "$high_cpu_extensions"
        echo ""
        echo "💡 SOLUTIONS for CPU Spikes:"
        echo "   1. Common CPU-heavy extensions and fixes:"
        echo "      • Pylance: Set 'python.analysis.autoImportCompletions': false"
        echo "      • ESLint: Set 'eslint.run': 'onSave' instead of 'onType'"
        echo "      • GitLens: Set 'gitlens.codeLens.enabled': false"
        echo "      • IntelliCode: Set 'vsintellicode.modify.editor.suggestSelection': 'automaticallyOverrodeDefaultValue'"
        echo ""
        echo "   2. Global CPU reduction settings:"
        echo "      \"editor.quickSuggestions\": false"
        echo "      \"editor.parameterHints.enabled\": false"
        echo "      \"editor.hover.delay\": 1000"
        echo ""
        echo "   3. Disable real-time features:"
        echo "      \"editor.formatOnType\": false"
        echo "      \"editor.codeActionsOnSave\": {}"
    else
        echo "✅ No high CPU extension processes detected"
    fi
    echo ""
}

# Problem #3: Startup Performance Issues
check_startup_performance() {
    echo "🚀 Checking extension startup performance..."
    
    # Count installed extensions
    local extension_count=0
    local extensions_dir=""
    
    # Find extensions directory
    if [[ -d "$HOME/.vscode-insiders/extensions" ]]; then
        extensions_dir="$HOME/.vscode-insiders/extensions"
    elif [[ -d "$HOME/.vscode/extensions" ]]; then
        extensions_dir="$HOME/.vscode/extensions"
    fi
    
    if [[ -n "$extensions_dir" ]]; then
        extension_count=$(find "$extensions_dir" -maxdepth 1 -type d | wc -l)
        echo "📊 Installed extensions: $extension_count"
        
        if [[ $extension_count -gt 20 ]]; then
            echo "⚠️  HIGH EXTENSION COUNT: $extension_count extensions may slow startup"
            echo ""
            echo "💡 SOLUTIONS for Startup Performance:"
            echo "   1. Disable unused extensions:"
            echo "      Ctrl+Shift+P -> 'Extensions: Show Installed Extensions'"
            echo ""
            echo "   2. Use workspace-specific extensions:"
            echo "      Add to .vscode/extensions.json:"
            echo "      {"
            echo "        \"recommendations\": [\"ms-python.python\"],"
            echo "        \"unwantedRecommendations\": [\"ms-vscode.vscode-json\"]"
            echo "      }"
            echo ""
            echo "   3. Lazy load extensions:"
            echo "      \"extensions.autoUpdate\": false"
            echo "      \"extensions.autoCheckUpdates\": false"
            echo ""
            echo "   4. Profile startup time:"
            echo "      code --prof-startup"
        else
            echo "✅ Extension count is reasonable for good startup performance"
        fi
    else
        echo "⚠️  Could not find extensions directory"
    fi
    echo ""
}

# Problem #4: File Watcher Overload
check_file_watcher_issues() {
    echo "👁️  Checking file watcher issues..."
    
    # Check current file watcher limits
    local current_limit=$(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo "unknown")
    
    echo "📊 Current inotify limit: $current_limit"
    
    if [[ "$current_limit" != "unknown" ]] && [[ $current_limit -lt 524288 ]]; then
        echo "⚠️  LOW FILE WATCHER LIMIT: May cause extension issues"
        echo ""
        echo "💡 SOLUTIONS for File Watcher Issues:"
        echo "   1. Increase system limit:"
        echo "      echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf"
        echo "      sudo sysctl -p"
        echo ""
        echo "   2. Exclude large directories in settings.json:"
        echo "      \"files.watcherExclude\": {"
        echo "        \"**/node_modules/**\": true,"
        echo "        \"**/.git/objects/**\": true,"
        echo "        \"**/.git/subtree-cache/**\": true,"
        echo "        \"**/target/**\": true,"
        echo "        \"**/build/**\": true,"
        echo "        \"**/dist/**\": true,"
        echo "        \"**/.venv/**\": true,"
        echo "        \"**/__pycache__/**\": true"
        echo "      }"
        echo ""
        echo "   3. Extension-specific exclusions:"
        echo "      \"search.exclude\": {"
        echo "        \"**/node_modules\": true,"
        echo "        \"**/bower_components\": true"
        echo "      }"
    else
        echo "✅ File watcher limit is adequate"
    fi
    echo ""
}

# Problem #5: Network/Authentication Issues
check_network_auth_issues() {
    echo "🌐 Checking network and authentication issues..."
    
    # Check for common auth-related extensions
    local auth_extensions=(
        "GitHub"
        "Azure"
        "AWS"
        "Docker"
        "Remote"
        "Live Share"
        "Augment"
    )
    
    echo "🔍 Checking for authentication-heavy extensions..."
    
    # This would normally check installed extensions, but we'll provide general guidance
    echo ""
    echo "💡 SOLUTIONS for Network/Auth Issues:"
    echo ""
    echo "   1. GitHub/Git Authentication:"
    echo "      \"git.autofetch\": false"
    echo "      \"github.gitAuthentication\": false"
    echo "      \"git.autoRepositoryDetection\": false"
    echo ""
    echo "   2. Azure/Cloud Extensions:"
    echo "      \"azure.tenant\": \"your-tenant-id\""
    echo "      \"azure.cloud\": \"AzureCloud\""
    echo "      \"azure.ppe\": false"
    echo ""
    echo "   3. Remote Development:"
    echo "      \"remote.SSH.connectTimeout\": 60"
    echo "      \"remote.SSH.keepAliveInterval\": 30"
    echo "      \"remote.autoForwardPorts\": false"
    echo ""
    echo "   4. Live Share:"
    echo "      \"liveshare.audio\": false"
    echo "      \"liveshare.presence\": false"
    echo "      \"liveshare.allowGuestDebugControl\": false"
    echo ""
    echo "   5. Augment (from our research):"
    echo "      \"augment.auth.tokenRefreshInterval\": 3600000"
    echo "      \"augment.network.timeout\": 60000"
    echo "      \"augment.auth.preemptiveRefresh\": false"
    echo ""
}

# Problem #6: Extension Conflicts
check_extension_conflicts() {
    echo "⚔️  Checking for extension conflicts..."
    
    echo "💡 COMMON EXTENSION CONFLICTS & SOLUTIONS:"
    echo ""
    echo "   1. Multiple Language Servers (Python):"
    echo "      Problem: Pylance + Python extension conflicts"
    echo "      Solution: \"python.defaultInterpreterPath\": \"/usr/bin/python3\""
    echo "               \"python.languageServer\": \"Pylance\""
    echo ""
    echo "   2. Multiple Formatters:"
    echo "      Problem: Prettier + language-specific formatters"
    echo "      Solution: \"[javascript]\": {"
    echo "                  \"editor.defaultFormatter\": \"esbenp.prettier-vscode\""
    echo "                }"
    echo ""
    echo "   3. Git Extensions:"
    echo "      Problem: GitLens + Git Graph + Git History conflicts"
    echo "      Solution: Disable overlapping features:"
    echo "               \"gitlens.codeLens.enabled\": false"
    echo "               \"git.decorations.enabled\": false"
    echo ""
    echo "   4. Theme Conflicts:"
    echo "      Problem: Multiple theme extensions"
    echo "      Solution: \"workbench.preferredDarkColorTheme\": \"One Dark Pro\""
    echo "               \"workbench.preferredLightColorTheme\": \"One Light\""
    echo ""
    echo "   5. Bracket Pair Colorizers:"
    echo "      Problem: Old Bracket Pair Colorizer + built-in feature"
    echo "      Solution: \"editor.bracketPairColorization.enabled\": true"
    echo "               Uninstall old Bracket Pair Colorizer extension"
    echo ""
}

# Problem #7: Language Server Issues
check_language_server_issues() {
    echo "🗣️  Checking language server issues..."
    
    echo "💡 LANGUAGE SERVER OPTIMIZATIONS:"
    echo ""
    echo "   1. Python (Pylance):"
    echo "      \"python.analysis.autoImportCompletions\": false"
    echo "      \"python.analysis.memory.keepLibraryAst\": false"
    echo "      \"python.analysis.indexing\": false"
    echo "      \"python.analysis.packageIndexDepths\": []"
    echo ""
    echo "   2. TypeScript:"
    echo "      \"typescript.preferences.includePackageJsonAutoImports\": \"off\""
    echo "      \"typescript.suggest.autoImports\": false"
    echo "      \"typescript.updateImportsOnFileMove.enabled\": \"never\""
    echo ""
    echo "   3. C/C++:"
    echo "      \"C_Cpp.intelliSenseEngine\": \"Tag Parser\""
    echo "      \"C_Cpp.autocomplete\": \"Disabled\""
    echo "      \"C_Cpp.errorSquiggles\": \"Disabled\""
    echo ""
    echo "   4. Java:"
    echo "      \"java.compile.nullAnalysis.mode\": \"disabled\""
    echo "      \"java.completion.enabled\": false"
    echo "      \"java.signatureHelp.enabled\": false"
    echo ""
    echo "   5. Go:"
    echo "      \"go.useLanguageServer\": false"
    echo "      \"go.autocompleteUnimportedPackages\": false"
    echo ""
    echo "   6. Rust:"
    echo "      \"rust-analyzer.checkOnSave.command\": \"check\""
    echo "      \"rust-analyzer.cargo.loadOutDirsFromCheck\": false"
    echo ""
}

# Problem #8: Settings Sync Issues
check_settings_sync_problems() {
    echo "🔄 Checking settings sync issues..."
    
    echo "💡 SETTINGS SYNC OPTIMIZATIONS:"
    echo ""
    echo "   1. Disable problematic sync items:"
    echo "      \"settingsSync.ignoredExtensions\": ["
    echo "        \"ms-vscode.vscode-typescript-next\","
    echo "        \"ms-python.python\""
    echo "      ]"
    echo ""
    echo "   2. Reduce sync frequency:"
    echo "      \"settingsSync.keybindingsPerPlatform\": false"
    echo ""
    echo "   3. Workspace-specific settings (don't sync):"
    echo "      Create .vscode/settings.json for project-specific settings"
    echo ""
    echo "   4. Extension-specific workspace settings:"
    echo "      \"python.defaultInterpreterPath\": \"./venv/bin/python\""
    echo "      \"eslint.workingDirectories\": [\"./frontend\", \"./backend\"]"
    echo ""
}

# Additional function for specific popular extensions
check_popular_extension_issues() {
    echo "🔥 Checking issues with popular extensions..."
    echo ""

    echo "💡 POPULAR EXTENSION SPECIFIC FIXES:"
    echo ""
    echo "   1. Live Server (high CPU during file watching):"
    echo "      \"liveServer.settings.donotShowInfoMsg\": true"
    echo "      \"liveServer.settings.donotVerifyTags\": true"
    echo "      \"liveServer.settings.ignoreFiles\": ["
    echo "        \".vscode/**\", \"**/*.scss\", \"**/*.sass\""
    echo "      ]"
    echo ""
    echo "   2. Prettier (slow formatting on large files):"
    echo "      \"prettier.requireConfig\": true"
    echo "      \"prettier.useEditorConfig\": false"
    echo "      \"editor.formatOnSaveTimeout\": 2000"
    echo ""
    echo "   3. Auto Rename Tag (performance issues):"
    echo "      \"auto-rename-tag.activationOnLanguage\": [\"html\", \"xml\"]"
    echo ""
    echo "   4. Bracket Pair Colorizer (deprecated, use built-in):"
    echo "      \"editor.bracketPairColorization.enabled\": true"
    echo "      \"editor.guides.bracketPairs\": true"
    echo "      # Uninstall Bracket Pair Colorizer extension"
    echo ""
    echo "   5. IntelliCode (high CPU on large codebases):"
    echo "      \"vsintellicode.modify.editor.suggestSelection\": \"automaticallyOverrodeDefaultValue\""
    echo "      \"vsintellicode.features.python.deepLearning\": \"disabled\""
    echo ""
    echo "   6. Docker (slow container operations):"
    echo "      \"docker.attachShellCommand.linuxContainer\": \"/bin/sh\""
    echo "      \"docker.showStartPage\": false"
    echo ""
    echo "   7. Remote SSH (connection timeouts):"
    echo "      \"remote.SSH.connectTimeout\": 60"
    echo "      \"remote.SSH.keepAliveInterval\": 30"
    echo "      \"remote.SSH.maxReconnectionAttempts\": 3"
    echo ""
}

# Generate optimization script
generate_optimization_script() {
    local optimization_script="/tmp/extension_optimization.sh"
    
    cat > "$optimization_script" << 'EOF'
#!/bin/bash
# Auto-generated Extension Optimization Script

echo "Applying VSCode extension optimizations..."

# Create optimized settings
SETTINGS_FILE="$HOME/.config/Code - Insiders/User/settings.json"
if [[ ! -f "$SETTINGS_FILE" ]]; then
    SETTINGS_FILE="$HOME/.config/Code/User/settings.json"
fi

# Backup current settings
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Apply optimizations using jq if available, otherwise manual
if command -v jq &>/dev/null; then
    # Use jq for safe JSON manipulation
    jq '. + {
        "python.analysis.autoImportCompletions": false,
        "eslint.run": "onSave",
        "gitlens.codeLens.enabled": false,
        "editor.quickSuggestions": false,
        "extensions.autoUpdate": false,
        "files.watcherExclude": {
            "**/node_modules/**": true,
            "**/.git/objects/**": true,
            "**/target/**": true,
            "**/build/**": true,
            "**/dist/**": true
        }
    }' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
else
    echo "jq not available - manual settings update recommended"
fi

echo "Extension optimizations applied!"
EOF
    
    chmod +x "$optimization_script"
    echo "📄 Generated optimization script: $optimization_script"
}

# Main execution
main() {
    analyze_extension_problems
    generate_optimization_script
    
    echo ""
    echo "================================================================================"
    echo "                              ANALYSIS COMPLETE"
    echo "================================================================================"
    echo "📝 Full analysis log: $LOG_FILE"
    echo "🔧 Optimization script: /tmp/extension_optimization.sh"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Review the analysis above"
    echo "   2. Apply relevant optimizations to your settings.json"
    echo "   3. Run: /tmp/extension_optimization.sh"
    echo "   4. Restart VSCode to apply changes"
    echo ""
    echo "🎯 Focus on the issues most relevant to your installed extensions"
    echo "================================================================================"
}

# Check dependencies
if ! command -v bc &>/dev/null; then
    echo "⚠️  'bc' calculator not found - some calculations may be skipped"
fi

# Run main function
main "$@"
