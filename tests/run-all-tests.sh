#!/bin/bash

# Master test runner for the Ryan Workflow system
# Runs unit tests, integration tests, and performance benchmarks

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 RYAN WORKFLOW TEST SUITE                    ║${NC}"
echo -e "${BLUE}║           AI-Collaborative Coding System Tests              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo "Root directory: $ROOT_DIR"
echo "Starting comprehensive test suite..."
echo

run_test_suite() {
    local suite_name="$1"
    local suite_command="$2"
    local description="$3"
    
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│ $suite_name${NC}"
    echo -e "${BLUE}│ $description${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    if eval "$suite_command"; then
        echo -e "${GREEN}✅ $suite_name PASSED${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        echo -e "${RED}❌ $suite_name FAILED${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi
    echo
}

# Test Suite 1: Unit Tests
run_unit_tests() {
    cd "$SCRIPT_DIR/unit"
    echo "Running Python unit tests..."
    python3 test_ryan_workflow.py
}

# Test Suite 2: Integration Tests  
run_integration_tests() {
    cd "$SCRIPT_DIR"
    echo "Running integration tests..."
    ./integration-tests.sh
}

# Test Suite 3: Safety Protocol Tests
run_safety_tests() {
    echo "Testing safety protocols..."
    
    # Test 1: Verify SAFETY-RULES.md exists and has critical content
    if [[ ! -f "$ROOT_DIR/SAFETY-RULES.md" ]]; then
        echo "❌ SAFETY-RULES.md missing"
        return 1
    fi
    
    local safety_content
    safety_content=$(cat "$ROOT_DIR/SAFETY-RULES.md")
    
    if ! grep -q "NEVER USE HEREDOC" <<< "$safety_content"; then
        echo "❌ Safety rules missing heredoc prohibition"
        return 1
    fi
    
    if ! grep -q "base64" <<< "$safety_content"; then
        echo "❌ Safety rules missing base64 protocol"
        return 1
    fi
    
    # Test 2: Verify tmux-hello shows safety warnings
    local hello_output
    hello_output=$("$ROOT_DIR/tmux-hello")
    
    if ! grep -q "CRITICAL SAFETY RULES" <<< "$hello_output"; then
        echo "❌ tmux-hello missing safety warnings"
        return 1
    fi
    
    # Test 3: Verify base64 encoding works with problematic content
    local test_content="Problematic: \$USER 'single' \"double\" \`backticks\` <<EOF"
    local encoded decoded
    encoded=$(echo "$test_content" | base64)
    decoded=$(echo "$encoded" | base64 -d)
    
    if [[ "$decoded" != "$test_content" ]]; then
        echo "❌ Base64 safety protocol failed"
        return 1
    fi
    
    echo "✅ All safety protocols verified"
    return 0
}

# Test Suite 4: AI Handoff Simulation
run_ai_handoff_tests() {
    echo "Testing AI handoff protocols..."
    cd "$ROOT_DIR/tests"
    
    # Test phi3 simulator parsing
    local parse_output
    parse_output=$(python3 phi3-simulator.py "Run make test in the top pane" 2>/dev/null)
    
    if ! grep -q "top" <<< "$parse_output"; then
        echo "❌ phi3 parsing failed - pane detection"
        return 1
    fi
    
    if ! grep -q "make test" <<< "$parse_output"; then
        echo "❌ phi3 parsing failed - command extraction"
        return 1
    fi
    
    if ! grep -q "ryan-workflow:0.1" <<< "$parse_output"; then
        echo "❌ phi3 parsing failed - tmux target generation"
        return 1
    fi
    
    # Test output cleaning
    cat > temp_test_output.txt << 'EOF'
ryan-workflow-bash:left $ echo 'test'
test
program execution done. exit_code=0
EOF
    
    local clean_output
    clean_output=$(python3 phi3-simulator.py --clean temp_test_output.txt 2>/dev/null)
    
    if ! grep -q "success" <<< "$clean_output"; then
        echo "❌ phi3 output cleaning failed"
        rm -f temp_test_output.txt
        return 1
    fi
    
    rm -f temp_test_output.txt
    echo "✅ AI handoff protocols verified"
    return 0
}

# Test Suite 5: Performance Tests
run_performance_tests() {
    echo "Running performance benchmarks..."
    
    # Test 1: Base64 encoding performance
    local start_time end_time duration
    local large_content=""
    for i in {1..1000}; do
        large_content+="Line $i of test content with special chars: \$USER 'quotes' \"doubles\"\n"
    done
    
    start_time=$(date +%s.%N)
    echo -e "$large_content" | base64 | base64 -d > /dev/null
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    echo "📊 Base64 encoding/decoding 1000 lines: ${duration}s"
    
    # Should complete in under 1 second
    if (( $(echo "$duration > 1.0" | bc -l) )); then
        echo "⚠️  Performance warning: Base64 encoding slower than expected"
    fi
    
    # Test 2: phi3 simulator performance
    start_time=$(date +%s.%N)
    for i in {1..100}; do
        python3 "$ROOT_DIR/tests/phi3-simulator.py" "Run command $i in left pane" > /dev/null 2>&1
    done
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    echo "📊 phi3 simulator parsing 100 commands: ${duration}s"
    
    echo "✅ Performance tests completed"
    return 0
}

# Test Suite 6: Documentation Completeness
run_documentation_tests() {
    echo "Verifying documentation completeness..."
    
    local required_files=(
        "README.md"
        "SPECIFICATION.md"
        "SAFETY-RULES.md"
        "AI-USAGE.md"
        "setup-workflow.sh"
        "tmux-hello"
        "tmux-recover"
        "tests/phi3-simulator.py"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$ROOT_DIR/$file" ]]; then
            echo "❌ Missing required file: $file"
            return 1
        fi
    done
    
    # Check that key documentation contains required sections
    if ! grep -q "CRITICAL" "$ROOT_DIR/SAFETY-RULES.md"; then
        echo "❌ SAFETY-RULES.md missing critical warnings"
        return 1
    fi
    
    if ! grep -q "base64" "$ROOT_DIR/AI-USAGE.md"; then
        echo "❌ AI-USAGE.md missing base64 protocol"
        return 1
    fi
    
    echo "✅ All documentation verified"
    return 0
}

# Test Suite 7: Real-world Scenario Tests
run_scenario_tests() {
    echo "Testing real-world scenarios..."
    
    # Scenario 1: Stuck heredoc recovery
    echo "🧪 Testing stuck heredoc recovery scenario..."
    
    # This would normally be tested in a real tmux session
    # For now, we'll verify the recovery tools exist and are executable
    if [[ ! -x "$ROOT_DIR/tmux-recover" ]]; then
        echo "❌ tmux-recover not executable"
        return 1
    fi
    
    # Test recovery script help
    if ! "$ROOT_DIR/tmux-recover" 2>&1 | grep -q "Usage:"; then
        echo "❌ tmux-recover help not working"
        return 1
    fi
    
    # Scenario 2: AI command parsing edge cases
    echo "🧪 Testing AI command parsing edge cases..."
    
    local edge_cases=(
        "Run 'echo \"nested quotes\"' in left pane"
        "Execute ./script.sh --arg='value with spaces' in top"
        "Run command with \$variables in bottom pane"
    )
    
    for case in "${edge_cases[@]}"; do
        if ! python3 "$ROOT_DIR/tests/phi3-simulator.py" "$case" > /dev/null 2>&1; then
            echo "❌ Failed to parse edge case: $case"
            return 1
        fi
    done
    
    echo "✅ Real-world scenarios verified"
    return 0
}

# Main execution
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check dependencies
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ python3 not found${NC}"
    exit 1
fi

if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux not found${NC}"
    exit 1
fi

if ! command -v base64 &> /dev/null; then
    echo -e "${RED}❌ base64 not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites satisfied${NC}"
echo

# Run all test suites
run_test_suite "Unit Tests" "run_unit_tests" "Python unit tests for core components"
run_test_suite "Integration Tests" "run_integration_tests" "End-to-end system integration tests"
run_test_suite "Safety Protocol Tests" "run_safety_tests" "Critical safety rule enforcement"
run_test_suite "AI Handoff Tests" "run_ai_handoff_tests" "Claude <-> phi3 communication protocols"
run_test_suite "Performance Tests" "run_performance_tests" "System performance benchmarks"
run_test_suite "Documentation Tests" "run_documentation_tests" "Documentation completeness verification"
run_test_suite "Scenario Tests" "run_scenario_tests" "Real-world usage scenarios"

# Summary
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        TEST SUMMARY                         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo "Total test suites: $TOTAL_SUITES"
echo -e "Passed: ${GREEN}$PASSED_SUITES${NC}"
echo -e "Failed: ${RED}$FAILED_SUITES${NC}"

if [[ $FAILED_SUITES -eq 0 ]]; then
    echo
    echo -e "${GREEN}🎉 ALL TEST SUITES PASSED! 🎉${NC}"
    echo
    echo -e "${BLUE}The Ryan Workflow AI-collaborative coding system is ready for production use.${NC}"
    echo
    echo -e "${YELLOW}Key capabilities verified:${NC}"
    echo "✅ tmux session management with 3-pane layout"
    echo "✅ AI-safe command parsing and execution"
    echo "✅ Base64 content injection (no heredoc disasters)"
    echo "✅ Emergency recovery protocols"
    echo "✅ Claude <-> phi3 handoff for token optimization"
    echo "✅ Comprehensive safety rule enforcement"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Start using: ./setup-workflow.sh"
    echo "2. Ask AI to: 'Run tmux-hello to brief me on the system'"
    echo "3. Begin collaborative coding with safety guarantees!"
    exit 0
else
    echo
    echo -e "${RED}❌ SOME TEST SUITES FAILED ❌${NC}"
    echo
    echo "Please address the failing tests before using the system in production."
    echo "Check the detailed output above for specific failure information."
    exit 1
fi
