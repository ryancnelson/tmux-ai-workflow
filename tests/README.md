# AI Handoff Testing

This directory contains a comprehensive test suite for the Claude ↔ phi3 handoff pattern using Perl's build process as a realistic benchmark.

## 🧪 Test Suite Overview

### **Quick Start**
```bash
# Run all tests
./run-all-tests.sh

# Run specific test types
./integration-tests.sh           # Integration tests
python3 unit/test_ryan_workflow.py  # Unit tests
python3 stress-tests.py          # Stress tests
```

### **Test Categories**

#### 1. **Unit Tests** (`unit/test_ryan_workflow.py`)
- ✅ phi3 natural language parsing
- ✅ Command generation and tmux targeting  
- ✅ Output cleaning and error detection
- ✅ Base64 safety protocols
- ✅ Pane mapping and timeout logic
- ✅ Edge case handling

#### 2. **Integration Tests** (`integration-tests.sh`)
- ✅ Complete tmux session lifecycle
- ✅ Multi-pane command execution
- ✅ Recovery script functionality
- ✅ Session persistence and reattachment
- ✅ Error handling workflows
- ✅ Real command execution

#### 3. **Stress Tests** (`stress-tests.py`)
- ⚡ High-volume parsing (1000+ commands)
- ⚡ Concurrent load testing (10+ workers)
- ⚡ Memory leak detection
- ⚡ Performance benchmarking
- ⚡ Edge case bombardment

#### 4. **Safety Protocol Tests**
- 🛡️ Heredoc prohibition enforcement
- 🛡️ Base64 encoding verification
- 🛡️ Recovery command validation
- 🛡️ Documentation completeness
- 🛡️ Warning visibility checks

#### 5. **AI Handoff Tests**
- 🤖 Claude → phi3 command translation
- 🤖 phi3 → Claude output cleaning
- 🤖 Token optimization verification
- 🤖 Error escalation protocols
- 🤖 Performance optimization

#### 6. **Real-World Scenarios**
- 🌍 Stuck heredoc recovery
- 🌍 Complex build processes (Perl)
- 🌍 Multi-step development workflows
- 🌍 Interactive program handling
- 🌍 Long-running command management

## Files

### **Core Test Files**
- **`run-all-tests.sh`** - Master test runner (executes all test suites)
- **`integration-tests.sh`** - End-to-end system integration tests
- **`stress-tests.py`** - High-load performance and stress testing
- **`unit/test_ryan_workflow.py`** - Python unit tests for core components

### **Demo and Simulation**
- **`test-ai-handoff.sh`** - Demonstrates the complete handoff pattern
- **`phi3-simulator.py`** - Shows what phi3 would do for parsing/cleaning
- **`perl-5.40.0/`** - Perl source code for realistic build testing
- **`README.md`** - This file

### **Expected Test Results**
```
╔══════════════════════════════════════════════════════════╗
║                        TEST SUMMARY                         ║
╚══════════════════════════════════════════════════════════╝

Total test suites: 7
Passed: 7
Failed: 0

🎉 ALL TEST SUITES PASSED! 🎉
```

## The Handoff Pattern

```
User Request (Natural Language)
    ↓
Claude (Strategic Analysis)
    ↓
phi3 (Command Translation) 
    ↓
tmux execution
    ↓
phi3 (Output Cleaning)
    ↓
Claude (Result Analysis & Next Steps)
```

## Quick Demo

### Test the AI handoff simulation:
```bash
./test-ai-handoff.sh
```

### Test phi3's natural language parsing:
```bash
./phi3-simulator.py "Run make clean in the top pane"
./phi3-simulator.py "Execute ./configure --prefix=/tmp in left pane"  
./phi3-simulator.py "Run the Perl test suite in bottom pane"
```

### Test phi3's output cleaning:
```bash
# Create some sample output and clean it
echo "ryan-workflow-bash:top $ make test
Running tests...
All tests passed
program execution done. exit_code=0" > sample_output.txt

./phi3-simulator.py --clean sample_output.txt
```

## What This Demonstrates

### **Claude's Role (High-Cost AI):**
- Strategic thinking: "I need to configure, then build, then test"
- Error analysis: "This configure error means missing dependencies"
- Context understanding: "These test failures are expected on macOS"
- Decision making: "I should increase the timeout for this complex build"

### **phi3's Role (Local AI):**
- **Command Translation:**
  - `"Run make clean in top pane"` → `tmux send-keys -t ryan-workflow:0.1 "make clean ; echo ; echo 'program execution done. exit_code=$?'" Enter`
  
- **Output Cleaning:**
  - Raw: `"ryan-workflow-bash:top $ make test\n[500 lines of build output]\nprogram execution done. exit_code=0"`
  - Clean: `{"output_type": "success", "exit_code": 0, "summary": "Command completed successfully"}`

- **Status Monitoring:**
  - Detecting completion markers
  - Handling timeouts
  - Extracting error information

## Benefits

1. **Token Efficiency**: Claude doesn't waste tokens on repetitive parsing
2. **Speed**: Local phi3 handles routine translation/cleanup instantly  
3. **Reliability**: Consistent command generation and output parsing
4. **Scalability**: phi3 can handle many simple tasks while Claude focuses on complex reasoning

## Real-World Usage

In the actual system:
1. User says: *"The Perl build failed in the top pane - can you debug it?"*
2. Claude thinks: *"I need to see what error occurred during the build"*
3. phi3 translates: `tmux capture-pane -t ryan-workflow:0.1 -p`
4. phi3 cleans the raw tmux output into structured error info
5. Claude analyzes: *"This is a missing dependency error - here's how to fix it"*
6. phi3 translates the fix into proper tmux commands
7. Cycle continues...

This keeps expensive Claude reasoning focused on the hard problems while phi3 handles the mechanical translation work.
