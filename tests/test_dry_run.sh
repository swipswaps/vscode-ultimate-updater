#!/bin/bash
################################################################################
# Test Suite for VSCode Ultimate Updater Dry Run Functionality
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATER_SCRIPT="$SCRIPT_DIR/../vscode_ultimate_updater.sh"
TEST_LOG="/tmp/vscode_updater_test_$(date +%Y%m%d_%H%M%S).log"

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$TEST_LOG"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    ((TESTS_RUN++))
    log_test "🧪 Running test: $test_name"
    
    if eval "$test_command" >> "$TEST_LOG" 2>&1; then
        local actual_result="PASS"
    else
        local actual_result="FAIL"
    fi
    
    if [[ "$actual_result" == "$expected_result" ]]; then
        ((TESTS_PASSED++))
        log_test "✅ PASS: $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log_test "❌ FAIL: $test_name (expected: $expected_result, got: $actual_result)"
        return 1
    fi
}

echo "================================================================================"
echo "                    VSCode Ultimate Updater Test Suite"
echo "                              $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================================"
echo "📝 Test log: $TEST_LOG"
echo ""

# Verify script exists and is executable
if [[ ! -f "$UPDATER_SCRIPT" ]]; then
    echo "❌ Updater script not found: $UPDATER_SCRIPT"
    exit 1
fi

if [[ ! -x "$UPDATER_SCRIPT" ]]; then
    echo "❌ Updater script not executable: $UPDATER_SCRIPT"
    exit 1
fi

echo "✅ Updater script found and executable"
echo ""

# Test 1: Help functionality
run_test "Help command" \
    "$UPDATER_SCRIPT --help" \
    "PASS"

# Test 2: Basic dry run
run_test "Basic dry run" \
    "$UPDATER_SCRIPT --dry-run" \
    "PASS"

# Test 3: Verbose dry run
run_test "Verbose dry run" \
    "$UPDATER_SCRIPT --dry-run --verbose" \
    "PASS"

# Test 4: Invalid option handling
run_test "Invalid option handling" \
    "$UPDATER_SCRIPT --invalid-option" \
    "FAIL"

# Test 5: Dry run output verification
echo "🔍 Testing dry run output content..."
DRY_RUN_OUTPUT=$("$UPDATER_SCRIPT" --dry-run 2>&1 || true)

# Check for expected patterns in dry run output
EXPECTED_PATTERNS=(
    "DRY RUN MODE"
    "Detected: VSCode"
    "Step 1: Safety Checks"
    "Step 2: Creating pre-update backup"
    "Step 3: Checking for VSCode"
    "Step 4: Verifying file integrity"
    "Step 5: Installing update"
    "Step 6: Applying performance optimizations"
)

PATTERN_TESTS_PASSED=0
for pattern in "${EXPECTED_PATTERNS[@]}"; do
    if echo "$DRY_RUN_OUTPUT" | grep -q "$pattern"; then
        log_test "✅ Found expected pattern: $pattern"
        ((PATTERN_TESTS_PASSED++))
    else
        log_test "❌ Missing expected pattern: $pattern"
    fi
    ((TESTS_RUN++))
done

if [[ $PATTERN_TESTS_PASSED -eq ${#EXPECTED_PATTERNS[@]} ]]; then
    ((TESTS_PASSED += PATTERN_TESTS_PASSED))
    log_test "✅ All dry run patterns found"
else
    ((TESTS_FAILED += (${#EXPECTED_PATTERNS[@]} - PATTERN_TESTS_PASSED)))
    log_test "❌ Some dry run patterns missing"
fi

# Test 6: Safety detection
echo ""
echo "🛡️  Testing safety detection..."

# Check if running inside VSCode
if [[ "${TERM_PROGRAM:-}" == "vscode" ]] || [[ -n "${VSCODE_PID:-}" ]]; then
    log_test "🔍 Running inside VSCode - testing safety detection"
    
    SAFETY_OUTPUT=$("$UPDATER_SCRIPT" --dry-run 2>&1 || true)
    if echo "$SAFETY_OUTPUT" | grep -q "SAFETY WARNING"; then
        ((TESTS_PASSED++))
        log_test "✅ Safety detection working"
    else
        ((TESTS_FAILED++))
        log_test "❌ Safety detection not working"
    fi
    ((TESTS_RUN++))
else
    log_test "ℹ️  Not running inside VSCode - skipping safety detection test"
fi

# Test 7: Backup directory creation
echo ""
echo "📦 Testing backup functionality..."

BACKUP_TEST_OUTPUT=$("$UPDATER_SCRIPT" --dry-run 2>&1 || true)
if echo "$BACKUP_TEST_OUTPUT" | grep -q "Creating pre-update backup"; then
    ((TESTS_PASSED++))
    log_test "✅ Backup creation test passed"
else
    ((TESTS_FAILED++))
    log_test "❌ Backup creation test failed"
fi
((TESTS_RUN++))

# Test 8: Platform detection
echo ""
echo "🌍 Testing platform detection..."

PLATFORM_OUTPUT=$("$UPDATER_SCRIPT" --dry-run 2>&1 || true)
CURRENT_PLATFORM=$(uname -s)

case "$CURRENT_PLATFORM" in
    Linux*)
        if echo "$PLATFORM_OUTPUT" | grep -q "Detected: VSCode.*on linux"; then
            ((TESTS_PASSED++))
            log_test "✅ Linux platform detection working"
        else
            ((TESTS_FAILED++))
            log_test "❌ Linux platform detection failed"
        fi
        ;;
    Darwin*)
        if echo "$PLATFORM_OUTPUT" | grep -q "Detected: VSCode.*on macos"; then
            ((TESTS_PASSED++))
            log_test "✅ macOS platform detection working"
        else
            ((TESTS_FAILED++))
            log_test "❌ macOS platform detection failed"
        fi
        ;;
    *)
        log_test "ℹ️  Unknown platform: $CURRENT_PLATFORM"
        ((TESTS_PASSED++))  # Don't fail on unknown platforms
        ;;
esac
((TESTS_RUN++))

# Test 9: VSCode variant detection
echo ""
echo "🔍 Testing VSCode variant detection..."

if command -v code-insiders &>/dev/null; then
    if echo "$PLATFORM_OUTPUT" | grep -q "insiders"; then
        ((TESTS_PASSED++))
        log_test "✅ VSCode Insiders detection working"
    else
        ((TESTS_FAILED++))
        log_test "❌ VSCode Insiders detection failed"
    fi
elif command -v code &>/dev/null; then
    if echo "$PLATFORM_OUTPUT" | grep -q "stable"; then
        ((TESTS_PASSED++))
        log_test "✅ VSCode Stable detection working"
    else
        ((TESTS_FAILED++))
        log_test "❌ VSCode Stable detection failed"
    fi
else
    if echo "$PLATFORM_OUTPUT" | grep -q "No VSCode installation detected"; then
        ((TESTS_PASSED++))
        log_test "✅ No VSCode detection working"
    else
        ((TESTS_FAILED++))
        log_test "❌ No VSCode detection failed"
    fi
fi
((TESTS_RUN++))

# Test 10: Log file creation
echo ""
echo "📝 Testing log file creation..."

# Run dry run and check if log file is created
DRY_RUN_LOG_OUTPUT=$("$UPDATER_SCRIPT" --dry-run --verbose 2>&1 || true)
if echo "$DRY_RUN_LOG_OUTPUT" | grep -q "Log file:"; then
    LOG_FILE_PATH=$(echo "$DRY_RUN_LOG_OUTPUT" | grep "Log file:" | sed 's/.*Log file: //' | awk '{print $1}')
    if [[ -f "$LOG_FILE_PATH" ]]; then
        ((TESTS_PASSED++))
        log_test "✅ Log file creation working: $LOG_FILE_PATH"
    else
        ((TESTS_FAILED++))
        log_test "❌ Log file not created: $LOG_FILE_PATH"
    fi
else
    ((TESTS_FAILED++))
    log_test "❌ Log file path not found in output"
fi
((TESTS_RUN++))

# Test Results Summary
echo ""
echo "================================================================================"
echo "                              TEST RESULTS"
echo "================================================================================"
echo "📊 Tests run: $TESTS_RUN"
echo "✅ Tests passed: $TESTS_PASSED"
echo "❌ Tests failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "🎉 All tests passed!"
    OVERALL_RESULT="PASS"
else
    echo "⚠️  Some tests failed"
    OVERALL_RESULT="FAIL"
fi

echo "📝 Detailed log: $TEST_LOG"
echo "================================================================================"

# Exit with appropriate code
if [[ "$OVERALL_RESULT" == "PASS" ]]; then
    exit 0
else
    exit 1
fi
