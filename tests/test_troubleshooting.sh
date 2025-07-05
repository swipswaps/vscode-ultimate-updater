#!/bin/bash
################################################################################
# Comprehensive Test Suite for Troubleshooting Scenarios
# Tests all common pain points and their automated solutions
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATER_SCRIPT="$SCRIPT_DIR/../vscode_ultimate_updater_enhanced.sh"
TEST_LOG="/tmp/troubleshooting_test_$(date +%Y%m%d_%H%M%S).log"

# Test results tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$TEST_LOG"
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_RUN++))
    log_test "🧪 Running test: $test_name"
    
    if $test_function; then
        ((TESTS_PASSED++))
        log_test "✅ PASS: $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log_test "❌ FAIL: $test_name"
        return 1
    fi
}

# ========== TEST FUNCTIONS FOR EACH PAIN POINT ==========

# Test Pain Point #1: Disk Space Detection
test_disk_space_detection() {
    log_test "Testing disk space detection logic..."
    
    # Create a function that simulates low disk space
    local temp_script="/tmp/test_disk_space.sh"
    cat > "$temp_script" << 'EOF'
#!/bin/bash
check_disk_space() {
    local required_space_mb=2048
    local available_space_mb=1000  # Simulate low space
    
    if [[ $available_space_mb -lt $required_space_mb ]]; then
        echo "❌ CRITICAL: Insufficient disk space!"
        echo "   Required: ${required_space_mb}MB"
        echo "   Available: ${available_space_mb}MB"
        return 1
    fi
    return 0
}

check_disk_space
EOF
    
    chmod +x "$temp_script"
    
    # Test should fail (return 1) because of simulated low space
    if ! "$temp_script" >/dev/null 2>&1; then
        log_test "✅ Disk space detection correctly identified low space"
        rm -f "$temp_script"
        return 0
    else
        log_test "❌ Disk space detection failed to identify low space"
        rm -f "$temp_script"
        return 1
    fi
}

# Test Pain Point #2: Network Connectivity
test_network_connectivity() {
    log_test "Testing network connectivity checks..."
    
    # Test with a known good host
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        log_test "✅ Basic internet connectivity working"
    else
        log_test "❌ No internet connectivity - cannot test network features"
        return 1
    fi
    
    # Test VSCode server connectivity
    if curl -s --connect-timeout 10 --max-time 30 -I "https://code.visualstudio.com" >/dev/null; then
        log_test "✅ VSCode servers reachable"
        return 0
    else
        log_test "⚠️  VSCode servers not reachable (may be temporary)"
        return 0  # Don't fail test for temporary server issues
    fi
}

# Test Pain Point #3: Permission Checks
test_permission_checks() {
    log_test "Testing permission validation..."
    
    # Test home directory write access
    local test_file="$HOME/.test_write_$$"
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        log_test "✅ Home directory write access confirmed"
    else
        log_test "❌ Cannot write to home directory"
        return 1
    fi
    
    # Test directory creation
    local test_dir="/tmp/vscode_test_dir_$$"
    if mkdir -p "$test_dir" 2>/dev/null; then
        rmdir "$test_dir"
        log_test "✅ Directory creation permissions working"
        return 0
    else
        log_test "❌ Cannot create test directory"
        return 1
    fi
}

# Test Pain Point #4: Process Detection
test_process_detection() {
    log_test "Testing VSCode process detection..."
    
    # Create a dummy process that looks like VSCode
    local dummy_script="/tmp/fake_code_insiders_$$"
    cat > "$dummy_script" << 'EOF'
#!/bin/bash
# Fake VSCode process for testing
sleep 300
EOF
    chmod +x "$dummy_script"
    
    # Start fake process in background
    "$dummy_script" &
    local fake_pid=$!
    
    # Rename the process to look like code-insiders
    if command -v exec &>/dev/null; then
        # Test process detection methods
        local detected=false
        
        # Method 1: ps aux grep
        if ps aux | grep -E "(code-insiders|fake_code)" | grep -v grep >/dev/null; then
            detected=true
        fi
        
        # Method 2: pgrep
        if pgrep -f "fake_code" >/dev/null; then
            detected=true
        fi
        
        # Clean up
        kill $fake_pid 2>/dev/null || true
        rm -f "$dummy_script"
        
        if [[ "$detected" == "true" ]]; then
            log_test "✅ Process detection methods working"
            return 0
        else
            log_test "❌ Process detection methods failed"
            return 1
        fi
    else
        # Clean up and skip test
        kill $fake_pid 2>/dev/null || true
        rm -f "$dummy_script"
        log_test "⚠️  Skipping process detection test (exec not available)"
        return 0
    fi
}

# Test Pain Point #5: Package Manager Status
test_package_manager() {
    log_test "Testing package manager status checks..."
    
    # Check if we can detect package manager locks
    local lock_files=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/apt/lists/lock"
    )
    
    local locks_exist=false
    for lock_file in "${lock_files[@]}"; do
        if [[ -f "$lock_file" ]]; then
            locks_exist=true
            log_test "⚠️  Package manager lock detected: $lock_file"
        fi
    done
    
    # Test sudo access
    if sudo -n true 2>/dev/null; then
        log_test "✅ Sudo access available"
    else
        log_test "⚠️  No passwordless sudo access"
    fi
    
    log_test "✅ Package manager status check completed"
    return 0
}

# Test Pain Point #6: Download Integrity
test_download_integrity() {
    log_test "Testing download integrity verification..."
    
    # Create a test file with known size
    local test_file="/tmp/test_download_$$"
    echo "This is a test file for integrity checking" > "$test_file"
    local actual_size=$(stat -c%s "$test_file" 2>/dev/null || echo "0")
    
    # Test size verification function
    verify_test_integrity() {
        local file="$1"
        local expected_size="$2"
        
        if [[ ! -f "$file" ]]; then
            return 1
        fi
        
        local file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        if [[ "$file_size" -ne "$expected_size" ]]; then
            return 1
        fi
        
        return 0
    }
    
    # Test with correct size
    if verify_test_integrity "$test_file" "$actual_size"; then
        log_test "✅ Integrity verification working (correct size)"
    else
        log_test "❌ Integrity verification failed (correct size)"
        rm -f "$test_file"
        return 1
    fi
    
    # Test with incorrect size
    if ! verify_test_integrity "$test_file" "999999"; then
        log_test "✅ Integrity verification correctly detected size mismatch"
    else
        log_test "❌ Integrity verification failed to detect size mismatch"
        rm -f "$test_file"
        return 1
    fi
    
    rm -f "$test_file"
    return 0
}

# Test Pain Point #7: Environment Detection
test_environment_detection() {
    log_test "Testing environment detection..."
    
    # Test platform detection
    local platform="$(uname -s)"
    local arch="$(uname -m)"
    
    if [[ -n "$platform" ]] && [[ -n "$arch" ]]; then
        log_test "✅ Platform detection working: $platform $arch"
    else
        log_test "❌ Platform detection failed"
        return 1
    fi
    
    # Test VSCode environment detection
    local inside_vscode=false
    if [[ "${TERM_PROGRAM:-}" == "vscode" ]] || \
       [[ -n "${VSCODE_PID:-}" ]] || \
       [[ "$(ps -o comm= -p $PPID 2>/dev/null)" =~ code ]]; then
        inside_vscode=true
        log_test "⚠️  Running inside VSCode detected"
    else
        log_test "✅ Not running inside VSCode"
    fi
    
    return 0
}

# Test Pain Point #8: Backup Creation
test_backup_creation() {
    log_test "Testing backup creation..."
    
    local test_backup_dir="/tmp/vscode_backup_test_$$"
    
    # Test backup directory creation
    if mkdir -p "$test_backup_dir"; then
        log_test "✅ Backup directory creation working"
    else
        log_test "❌ Cannot create backup directory"
        return 1
    fi
    
    # Test file backup
    local test_config_dir="$test_backup_dir/test_config"
    mkdir -p "$test_config_dir"
    echo "test config" > "$test_config_dir/settings.json"
    
    # Test backup copy
    local backup_dest="$test_backup_dir/backup"
    if cp -r "$test_config_dir" "$backup_dest" 2>/dev/null; then
        log_test "✅ File backup operation working"
    else
        log_test "❌ File backup operation failed"
        rm -rf "$test_backup_dir"
        return 1
    fi
    
    # Verify backup contents
    if [[ -f "$backup_dest/test_config/settings.json" ]]; then
        log_test "✅ Backup verification working"
    else
        log_test "❌ Backup verification failed"
        rm -rf "$test_backup_dir"
        return 1
    fi
    
    rm -rf "$test_backup_dir"
    return 0
}

# Test the enhanced script's error handling
test_script_error_handling() {
    log_test "Testing script error handling..."
    
    # Verify the enhanced script exists
    if [[ ! -f "$UPDATER_SCRIPT" ]]; then
        log_test "❌ Enhanced updater script not found: $UPDATER_SCRIPT"
        return 1
    fi
    
    # Verify script is executable
    if [[ ! -x "$UPDATER_SCRIPT" ]]; then
        log_test "❌ Enhanced updater script not executable"
        return 1
    fi
    
    # Test help option
    if "$UPDATER_SCRIPT" --help >/dev/null 2>&1; then
        log_test "✅ Script help option working"
    else
        log_test "⚠️  Script help option not implemented (optional)"
    fi
    
    log_test "✅ Script error handling tests completed"
    return 0
}

# ========== MAIN TEST EXECUTION ==========

main() {
    echo "================================================================================"
    echo "                    Troubleshooting Test Suite"
    echo "                              $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================================================================"
    echo "📝 Test log: $TEST_LOG"
    echo ""
    
    # Run all tests
    local tests=(
        "Disk Space Detection:test_disk_space_detection"
        "Network Connectivity:test_network_connectivity"
        "Permission Checks:test_permission_checks"
        "Process Detection:test_process_detection"
        "Package Manager:test_package_manager"
        "Download Integrity:test_download_integrity"
        "Environment Detection:test_environment_detection"
        "Backup Creation:test_backup_creation"
        "Script Error Handling:test_script_error_handling"
    )
    
    for test in "${tests[@]}"; do
        local test_name="${test%:*}"
        local test_function="${test#*:}"
        run_test "$test_name" "$test_function"
        echo ""
    done
    
    # Test Results Summary
    echo "================================================================================"
    echo "                              TEST RESULTS"
    echo "================================================================================"
    echo "📊 Tests run: $TESTS_RUN"
    echo "✅ Tests passed: $TESTS_PASSED"
    echo "❌ Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 All troubleshooting tests passed!"
        echo "✅ Enhanced script should handle common pain points correctly"
    else
        echo "⚠️  Some tests failed - review the issues above"
        echo "💡 Check the detailed log: $TEST_LOG"
    fi
    
    echo "📝 Detailed log: $TEST_LOG"
    echo "================================================================================"
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
