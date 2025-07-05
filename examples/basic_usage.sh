#!/bin/bash
################################################################################
# Basic Usage Examples for VSCode Ultimate Updater
################################################################################

echo "VSCode Ultimate Updater - Basic Usage Examples"
echo "=============================================="

# Example 1: First-time user workflow
echo ""
echo "Example 1: First-time user (recommended workflow)"
echo "------------------------------------------------"
echo "# 1. Test what would happen (safe)"
echo "./vscode_ultimate_updater.sh --dry-run"
echo ""
echo "# 2. Review the output, then run for real"
echo "./vscode_ultimate_updater.sh"
echo ""

# Example 2: Regular update check
echo "Example 2: Regular update check"
echo "-------------------------------"
echo "# Quick update with safety checks"
echo "./vscode_ultimate_updater.sh"
echo ""

# Example 3: Verbose output for troubleshooting
echo "Example 3: Detailed output"
echo "--------------------------"
echo "# See exactly what's happening"
echo "./vscode_ultimate_updater.sh --verbose"
echo ""

# Example 4: Force update
echo "Example 4: Force update"
echo "-----------------------"
echo "# Update even if version appears current"
echo "./vscode_ultimate_updater.sh --force"
echo ""

# Example 5: Dry run with verbose output
echo "Example 5: Detailed analysis"
echo "----------------------------"
echo "# Comprehensive analysis without changes"
echo "./vscode_ultimate_updater.sh --dry-run --verbose"
echo ""

# Example 6: Quick update without backup
echo "Example 6: Quick update (advanced users)"
echo "----------------------------------------"
echo "# Faster update, but less safe"
echo "./vscode_ultimate_updater.sh --skip-backup"
echo ""

# Example 7: Help and information
echo "Example 7: Getting help"
echo "----------------------"
echo "# Show all available options"
echo "./vscode_ultimate_updater.sh --help"
echo ""

# Example 8: Combining options
echo "Example 8: Combining options"
echo "----------------------------"
echo "# Force update with verbose output"
echo "./vscode_ultimate_updater.sh --force --verbose"
echo ""
echo "# Dry run with verbose output"
echo "./vscode_ultimate_updater.sh --dry-run --verbose"
echo ""

echo "=============================================="
echo "Choose the example that fits your needs!"
echo "For safety, always start with --dry-run"
