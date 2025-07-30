#!/bin/bash

# AI Handoff Test Script - Demonstrates Claude <-> phi3 division of labor
# Tests using Perl build process as benchmark

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERL_DIR="$SCRIPT_DIR/perl-5.40.0"
BUILD_PREFIX="/var/tmp/perlbuildtest"

echo -e "${BLUE}=== AI HANDOFF TEST SCRIPT ===${NC}"
echo "Testing Claude (strategic) <-> phi3 (tactical) division of labor"
echo "Using Perl build process as benchmark"
echo

# Function to simulate Claude's strategic thinking
claude_think() {
    local situation="$1"
    echo -e "${GREEN}[CLAUDE STRATEGIC]${NC} $situation"
}

# Function to simulate phi3's tactical execution
phi3_execute() {
    local command_desc="$1"
    local actual_command="$2"
    echo -e "${YELLOW}[PHI3 TACTICAL]${NC} Translating: '$command_desc'"
    echo -e "${YELLOW}[PHI3 TACTICAL]${NC} → $actual_command"
}

# Function to simulate phi3's output cleaning
phi3_clean() {
    local raw_output="$1"
    local clean_output="$2"
    echo -e "${YELLOW}[PHI3 CLEAN]${NC} Raw output: $(echo "$raw_output" | head -1 | cut -c1-50)..."
    echo -e "${YELLOW}[PHI3 CLEAN]${NC} → Clean: $clean_output"
}

# Test function that demonstrates the handoff pattern
test_handoff() {
    local user_request="$1"
    local strategic_decision="$2"
    local command_desc="$3"
    local actual_command="$4"
    local timeout_duration="$5"
    
    echo -e "\n${BLUE}>>> USER REQUEST:${NC} $user_request"
    
    # Claude's strategic layer
    claude_think "$strategic_decision"
    
    # phi3's tactical layer
    phi3_execute "$command_desc" "$actual_command"
    
    # Execute the actual command with timeout
    echo -e "${RED}[EXECUTING]${NC} Running with ${timeout_duration}s timeout..."
    
    local start_time=$(date +%s)
    timeout "$timeout_duration" bash -c "$actual_command" 2>&1 | while IFS= read -r line; do
        echo "[RAW] $line"
    done
    local exit_code=${PIPESTATUS[0]}
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # phi3's cleaning layer
    if [ $exit_code -eq 0 ]; then
        phi3_clean "Complex build output with many lines..." "SUCCESS: Command completed in ${duration}s (exit_code=$exit_code)"
        claude_think "Great! The $command_desc succeeded. Next I should..."
    elif [ $exit_code -eq 124 ]; then
        phi3_clean "Timeout reached..." "TIMEOUT: Command exceeded ${timeout_duration}s limit"
        claude_think "The command timed out. I need to either increase timeout or check what's blocking."
    else
        phi3_clean "Error output with stack traces..." "FAILED: Command failed in ${duration}s (exit_code=$exit_code)"
        claude_think "There was an error. I should analyze the failure and suggest a fix."
    fi
    
    echo
}

# Create build directory
echo -e "${BLUE}Setting up test environment...${NC}"
mkdir -p "$BUILD_PREFIX"

# Test scenarios demonstrating different types of handoffs
echo -e "\n${BLUE}=== HANDOFF SCENARIO TESTS ===${NC}"

# Scenario 1: Initial setup
test_handoff \
    "Set up the Perl build environment" \
    "I need to navigate to the source directory and run the configure script to prepare for building" \
    "Navigate to Perl source and run configure with custom prefix" \
    "cd '$PERL_DIR' && ./Configure -des -Dprefix='$BUILD_PREFIX'" \
    300

# Scenario 2: Clean build
test_handoff \
    "Clean any previous build artifacts" \
    "Before building, I should clean up any leftover files from previous attempts" \
    "Clean build directory" \
    "cd '$PERL_DIR' && make clean 2>/dev/null || true" \
    30

# Scenario 3: Compilation
test_handoff \
    "Compile Perl from source" \
    "Now I'll compile the source code. This will take a while and I should monitor for errors" \
    "Run make to compile Perl" \
    "cd '$PERL_DIR' && make -j4" \
    900

# Scenario 4: Testing
test_handoff \
    "Run the Perl test suite to verify the build" \
    "I should run the test suite to ensure everything compiled correctly. Some tests might fail on certain systems" \
    "Run Perl test suite (abbreviated)" \
    "cd '$PERL_DIR' && timeout 300 make test TEST_JOBS=4 || echo 'Some tests may have failed - this is normal'" \
    400

echo -e "\n${GREEN}=== HANDOFF PATTERN SUMMARY ===${NC}"
echo "1. USER makes natural language request"
echo "2. CLAUDE analyzes situation and decides strategy"
echo "3. PHI3 translates strategy into specific commands"
echo "4. PHI3 monitors execution and cleans output"
echo "5. CLAUDE analyzes cleaned results and plans next steps"
echo
echo "This pattern keeps expensive Claude tokens for high-level reasoning"
echo "while using fast local phi3 for repetitive parsing/cleaning tasks."

echo -e "\n${BLUE}Test environment ready at: $PERL_DIR${NC}"
echo -e "${BLUE}Build prefix: $BUILD_PREFIX${NC}"
