# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a tmux-based AI-collaborative coding system that enables seamless collaboration between developers and AI assistants. It features Docker containerization for safety and token optimization through local model integration.

## Key Commands

### Setup and Execution
```bash
# Start the AI workflow (Docker mode - recommended)
./setup-workflow.sh

# Start in native mode (runs directly on host)
./setup-workflow.sh --native

# Get system briefing and operational guide
./tmux-hello

# Recovery tools for stuck sessions
./tmux-recover [pane] emergency
```

### Testing
```bash
# Run all test suites
./tests/run-all-tests.sh

# Run specific test categories
./tests/integration-tests.sh           # Integration tests
python3 tests/unit/test_ryan_workflow.py  # Unit tests
python3 tests/stress-tests.py          # Stress tests

# Test AI handoff pattern simulation
./tests/test-ai-handoff.sh
```

## Architecture

### Session Structure
- **Session Name**: `ai-workflow`
- **Three-pane layout**:
  - Left pane (full height): `ai-workflow-bash:left $`
  - Top pane (upper right): `ai-workflow-bash:top $`
  - Bottom pane (lower right): `ai-workflow-bash:bottom $`

### Execution Modes
- **Docker Mode** (default): Commands execute in isolated Ubuntu 22.04 container
  - Container name: `ai-workflow-dev`
  - Workspace: `/workspace` (mapped from current directory)
  - Pre-installed: Python 3, Node.js, build tools, Claude Code CLI
- **Native Mode**: Commands run directly on host system

### AI Integration Pattern
The system implements a two-tier AI architecture:
1. **High-cost AI (Claude)**: Strategic analysis, complex reasoning, error diagnosis
2. **Local models (phi3/Ollama)**: Command translation, output parsing, routine tasks

## Critical Safety Protocols

### NEVER Use Heredoc Syntax
```bash
# ❌ NEVER DO THIS - Will break sessions
cat << EOF > file.txt
content
EOF

# ✅ ALWAYS use base64 encoding instead
echo "Y29udGVudAo=" | base64 -d > file.txt
```

### Base64 Protocol for File Operations
```bash
# 1. Encode content
echo "your content" | base64

# 2. Inject safely
echo "WW91ciBjb250ZW50Cg==" | base64 -d > filename.txt
```

### Recovery Protocol
When panes get stuck (showing `>` prompt instead of normal bash prompt):
```bash
# From outside tmux or different pane
tmux send-keys -t ai-workflow:0.X C-c
tmux send-keys -t ai-workflow:0.X "clear" Enter

# Or use recovery script
./tmux-recover [left|top|bottom] emergency
```

## Command Execution Patterns

### Standard Commands
```bash
# Pattern for commands expected to complete
timeout [DURATION] [COMMAND] ; echo ; echo "program execution done. exit_code=$?"
```

### Docker Execution
When in Docker mode, tmux commands must be prefixed:
```bash
docker exec -it ai-workflow-dev tmux [command]
```

## File Structure

### Core Scripts
- `setup-workflow.sh`: Session setup and management (Docker/native)
- `tmux-hello`: Complete system briefing
- `tmux-recover`: Recovery tools for stuck sessions

### Docker Configuration
- `Dockerfile`: Ubuntu 22.04 with development tools
- `docker-compose.yml`: Container orchestration

### Documentation
- `README.md`: User-facing documentation
- `SPECIFICATION.md`: Complete technical specification
- `SAFETY-RULES.md`: Critical safety protocols (READ FIRST)
- `AI-USAGE.md`: AI assistant usage examples

### Testing
- `tests/`: Comprehensive test suite with phi3 simulation
- Tests include unit, integration, stress, and safety protocol validation

## Development Workflow

1. Start session: `./setup-workflow.sh`
2. Use natural language commands targeting specific panes
3. System handles tmux communication, command execution, and output parsing
4. Recovery tools available for session management
5. Docker isolation provides safety layer

## Token Optimization Strategy

- phi3/local models handle routine command translation and output parsing
- Claude focuses on strategic thinking, error analysis, and complex reasoning
- Base64 encoding ensures safe text injection
- Structured communication protocols minimize token waste

## Integration Notes

- AWS Bedrock integration with Claude Sonnet 4
- VSCode dev container support
- Persistent context across sessions
- Host file access via Claude filesystem tools (even in Docker mode)
- Port forwarding for development servers (3000, 5000, 8000, 8080, 8443, 9000)