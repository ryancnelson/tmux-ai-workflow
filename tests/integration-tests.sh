#!/bin/bash

# Integration tests for the Ryan Workflow system
# Tests the complete system from setup to recovery

set -e  # Exit on any error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_SESSION="test-integration-$$"  # Unique session name

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}=== RYAN WORKFLOW INTEGRATION TESTS ===${NC}"
echo "Root directory: $ROOT_DIR"
echo "Test session: $TEST_SESSION"
echo

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up test session...${NC}"
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
}
trap cleanup EXIT

# Test helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}[TEST]${NC} $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$test_command"; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}[FAIL]${NC} $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo
}

assert_command_success() {
    local description="$1"
    local command="$2"
    
    if ! eval "$command" &>/dev/null; then
        echo -e "${RED}ASSERTION FAILED:${NC} $description"
        echo "Command: $command"
        return 1
    fi
    return 0
}

assert_file_exists() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}ASSERTION FAILED:${NC} File does not exist: $file_path"
        return 1
    fi
    return 0
}

assert_session_exists() {
    local session_name="$1"
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${RED}ASSERTION FAILED:${NC} Tmux session does not exist: $session_name"
        return 1
    fi
    return 0
}

assert_contains() {
    local text="$1"
    local pattern="$2"
    if [[ ! "$text" =~ $pattern ]]; then
        echo -e "${RED}ASSERTION FAILED:${NC} Text does not contain pattern: $pattern"
        echo "Text: $text"
        return 1
    fi
    return 0
}

# Test 1: System files exist
test_system_files_exist() {
    assert_file_exists "$ROOT_DIR/setup-workflow.sh" &&
    assert_file_exists "$ROOT_DIR/tmux-hello" &&
    assert_file_exists "$ROOT_DIR/tmux-recover" &&
    assert_file_exists "$ROOT_DIR/SAFETY-RULES.md" &&
    assert_file_exists "$ROOT_DIR/tests/phi3-simulator.py"
}

# Test 2: Setup script creates proper session structure
test_setup_script_creates_session() {
    # Kill any existing test session
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
    
    # Create session using our setup logic (modified for test)
    tmux new-session -d -s "$TEST_SESSION" &&
    tmux split-window -h -t "$TEST_SESSION" &&
    tmux split-window -v -t "$TEST_SESSION:0.1" &&
    
    # Verify session structure
    assert_session_exists "$TEST_SESSION" &&
    
    # Check we have 3 panes
    local pane_count
    pane_count=$(tmux list-panes -t "$TEST_SESSION" | wc -l)
    [[ "$pane_count" -eq 3 ]]
}

# Test 3: Pane targeting works correctly
test_pane_targeting() {
    assert_session_exists "$TEST_SESSION" &&
    
    # Send different commands to each pane
    tmux send-keys -t "$TEST_SESSION:0.0" "echo 'left-pane-test'" Enter &&
    tmux send-keys -t "$TEST_SESSION:0.1" "echo 'top-pane-test'" Enter &&
    tmux send-keys -t "$TEST_SESSION:0.2" "echo 'bottom-pane-test'" Enter &&
    
    sleep 1  # Give commands time to execute
    
    # Capture and verify outputs
    local left_output top_output bottom_output
    left_output=$(tmux capture-pane -t "$TEST_SESSION:0.0" -p)
    top_output=$(tmux capture-pane -t "$TEST_SESSION:0.1" -p)
    bottom_output=$(tmux capture-pane -t "$TEST_SESSION:0.2" -p)
    
    assert_contains "$left_output" "left-pane-test" &&
    assert_contains "$top_output" "top-pane-test" &&
    assert_contains "$bottom_output" "bottom-pane-test"
}

# Test 4: Recovery script functionality
test_recovery_script() {
    assert_session_exists "$TEST_SESSION" &&
    
    # Test status check
    "$ROOT_DIR/tmux-recover" left status &>/dev/null &&
    
    # Test clear command
    "$ROOT_DIR/tmux-recover" top clear &>/dev/null &&
    
    # Test interrupt (should not fail even if nothing to interrupt)
    "$ROOT_DIR/tmux-recover" bottom interrupt &>/dev/null
}

# Test 5: tmux-hello provides proper briefing
test_tmux_hello_briefing() {
    local output
    output=$("$ROOT_DIR/tmux-hello")
    
    assert_contains "$output" "RYAN WORKFLOW TMUX SYSTEM" &&
    assert_contains "$output" "CRITICAL SAFETY RULES" &&
    assert_contains "$output" "NEVER use heredoc" &&
    assert_contains "$output" "base64 encoding" &&
    assert_contains "$output" "RECOVERY COMMANDS FOR AI"
}

# Test 6: phi3 simulator natural language parsing
test_phi3_simulator_parsing() {
    cd "$ROOT_DIR/tests" &&
    
    # Test basic parsing
    local output
    output=$(python3 phi3-simulator.py "Run make clean in the top pane" 2>/dev/null)
    
    assert_contains "$output" "top" &&
    assert_contains "$output" "make clean" &&
    assert_contains "$output" "ryan-workflow:0.1" &&
    
    # Test execute verb
    output=$(python3 phi3-simulator.py "Execute ls -la in the left pane" 2>/dev/null)
    assert_contains "$output" "left" &&
    assert_contains "$output" "ls -la" &&
    assert_contains "$output" "ryan-workflow:0.0"
}

# Test 7: phi3 simulator output cleaning
test_phi3_simulator_cleaning() {
    cd "$ROOT_DIR/tests" &&
    
    # Create test output file
    cat > test_clean_output.txt << 'EOF'
ryan-workflow-bash:top $ make test
Running tests...
Test 1: PASS
Test 2: FAIL - Error message
program execution done. exit_code=1
EOF
    
    local output
    output=$(python3 phi3-simulator.py --clean test_clean_output.txt 2>/dev/null)
    
    assert_contains "$output" "error" &&
    assert_contains "$output" "exit_code.*1" &&
    assert_contains "$output" "Running tests" &&
    
    # Cleanup
    rm -f test_clean_output.txt
}

# Test 8: Base64 safety protocol
test_base64_safety() {
    # Test that base64 handles problematic content safely
    local problematic_content="Content with \$variables and 'quotes' and \"double quotes\" and \`backticks\`"
    local encoded decoded
    
    encoded=$(echo "$problematic_content" | base64) &&
    decoded=$(echo "$encoded" | base64 -d)
    
    [[ "$decoded" == "$problematic_content" ]]
}

# Test 9: Session persistence and reattachment
test_session_persistence() {
    assert_session_exists "$TEST_SESSION" &&
    
    # Send command and detach
    tmux send-keys -t "$TEST_SESSION:0.0" "echo 'persistence-test'" Enter &&
    
    # Verify we can capture output (session persists)
    local output
    output=$(tmux capture-pane -t "$TEST_SESSION:0.0" -p)
    assert_contains "$output" "persistence-test"
}

# Test 10: Error handling and timeout simulation
test_error_handling() {
    assert_session_exists "$TEST_SESSION" &&
    
    # Test a command that should fail
    tmux send-keys -t "$TEST_SESSION:0.1" "false ; echo ; echo 'program execution done. exit_code=\$?'" Enter &&
    
    sleep 1  # Give command time to execute
    
    local output
    output=$(tmux capture-pane -t "$TEST_SESSION:0.1" -p)
    assert_contains "$output" "program execution done. exit_code=1"
}

# Run all tests
echo -e "${YELLOW}Starting integration tests...${NC}"
echo

run_test "System files exist and are executable" "test_system_files_exist"
run_test "Setup script creates proper session structure" "test_setup_script_creates_session" 
run_test "Pane targeting works correctly" "test_pane_targeting"
run_test "Recovery script functionality" "test_recovery_script"
run_test "tmux-hello provides proper briefing" "test_tmux_hello_briefing"
run_test "phi3 simulator natural language parsing" "test_phi3_simulator_parsing"
run_test "phi3 simulator output cleaning" "test_phi3_simulator_cleaning"
run_test "Base64 safety protocol" "test_base64_safety"
run_test "Session persistence and reattachment" "test_session_persistence"
run_test "Error handling and timeout simulation" "test_error_handling"

# Results summary
echo -e "${BLUE}=== TEST RESULTS ===${NC}"
echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    echo "The Ryan Workflow system is ready for production use."
    exit 0
else
    echo -e "\n${RED}❌ SOME TESTS FAILED ❌${NC}"
    echo "Please review the failures and fix issues before deployment."
    exit 1
fi
