# Ryan Workflow - AI-Collaborative Coding System

## Overview
A tmux-based system that enables seamless collaboration between a human developer and an AI assistant through structured terminal sessions with named panes and standardized communication protocols.

## Core Architecture

### Session Structure
- **Session Name**: `ryan-workflow`
- **Layout**: Three-pane layout
  - **Left Pane**: Named "left" - Full height, left half of screen
  - **Top Pane**: Named "top" - Upper right quadrant  
  - **Bottom Pane**: Named "bottom" - Lower right quadrant

### Configuration Requirements
- **Mouse Mode**: Enabled for intuitive pane navigation
- **Custom Bash Prompts**: Each pane displays `ryan-workflow-bash:[PANE_NAME]` 
  - Left pane: `ryan-workflow-bash:left $ `
  - Top pane: `ryan-workflow-bash:top $ `
  - Bottom pane: `ryan-workflow-bash:bottom $ `

## AI Assistant Command Execution Protocol

### Pre-Execution Validation
1. **Prompt Verification**: Before sending commands, AI must capture and verify the appropriate bash prompt is present and waiting for input
2. **Pane State Check**: Confirm the target pane is in a ready state (not running another process)

### Command Execution Patterns

#### Standard Commands (Expected to Complete)
```bash
# Pattern for commands expected to finish
timeout [DURATION] [COMMAND] ; echo ; echo "program execution done. exit_code=$?"
```
- Use appropriate timeout durations based on expected command completion time
- Include completion markers for easy parsing by AI

#### Interactive Programs
- **Use Cases**: mysql client, REPLs, menu-driven programs
- **Protocol**: Examine current screen state before input rather than checking for prompts
- **Method**: Use `tmux capture-pane` to understand current program state

### Text Input/Editing Protocol

#### File Content Injection
**NEVER use heredoc syntax** due to shell escaping complexity.

**Preferred Method**: Base64 encoding with pipe to tee
```bash
# For new files
echo "[BASE64_ENCODED_CONTENT]" | base64 -d | tee output.filename.txt

# For appending to existing files  
echo "[BASE64_ENCODED_CONTENT]" | base64 -d | tee -a output.filename.txt
```

**Benefits**:
- Eliminates shell escaping issues
- Handles special characters safely
- Simplifies quote/apostrophe handling
- Reliable for multi-line content

### AI Assistant Commands

#### Core tmux Operations
- `tmux send-keys -t ryan-workflow:[PANE_NAME] "[COMMAND]" Enter`
- `tmux capture-pane -t ryan-workflow:[PANE_NAME] -p`
- `tmux capture-pane -t ryan-workflow:[PANE_NAME] -S -[LINES]`

#### Workflow Commands
- **Execute in Pane**: Natural language - "Run `npm test` in the top pane"
- **Check Pane Status**: "Check what's running in the left pane"
- **Capture Output**: "Show me the output from the bottom pane"

## Session Management

### Session Initialization
```bash
# Create session with proper layout (or attach if exists)
./setup-workflow.sh
```

### Prompt Configuration
Each pane requires custom PS1 environment variable:
```bash
export PS1="ryan-workflow-bash:[PANE_NAME] $ "
```

## Implementation Details

### 1. Session Setup
- **Setup Script**: `setup-workflow.sh` automatically handles:
  - Check if `ryan-workflow` session exists
  - If exists: attach to existing session
  - If not: create new session with proper layout, mouse mode, and custom prompts
  - Set up bash prompts in each pane during session creation

### 2. AI Command Interface
- **Natural Language Processing**: AI interprets commands like:
  - "Run `npm test` in the top pane"
  - "Check what's happening in the left pane"
  - "Execute `git status` in the bottom pane"

### 3. Prompt Management
- **Setup**: Bash prompts configured during session initialization
- **Flexibility**: AI can adjust prompts to include additional info when needed
- **Reset**: AI can restore to standard `ryan-workflow-bash:[PANE_NAME]` format on request

### 4. Command Timeout Defaults
- **Quick commands** (ls, cd, etc.): 5-10 seconds
- **Build commands**: 60-300 seconds  
- **Test suites**: 300-600 seconds
- **Interactive programs**: No timeout (monitor state instead)

### 5. Error Handling Strategy
- **Incomplete Commands**: AI detects when commands don't complete cleanly
- **Adaptive Response**: AI adjusts strategy based on error conditions
- **Recovery**: AI can suggest corrections or alternative approaches

### 6. Containerization & Portability
- **Docker Integration**: Entire system designed for containerization
- **MCP Service**: Future integration with `mcp serve` for standard SSE MCP service
- **Portability**: Docker wrapper ensures consistent behavior across environments

## Use Cases

### Development Workflows
- **Left Pane**: Primary coding/editing environment
- **Top Pane**: Build/compile/test commands
- **Bottom Pane**: Version control, file operations, monitoring

### Interactive Sessions
- Database clients (mysql, psql)
- Language REPLs (python, node, etc.)
- Development servers
- Log monitoring

## Implementation Notes

### Error Handling
- AI should validate command success through exit codes
- Capture and analyze error output
- Implement retry logic for transient failures

### State Management
- AI maintains awareness of what's running in each pane
- Track interactive vs. batch command states
- Handle long-running processes appropriately

### Security Considerations
- Base64 encoding prevents injection attacks
- Timeout commands prevent runaway processes
- Validate pane states before command execution

## Future Enhancements
- Session persistence across reconnections
- Command history tracking per pane
- Automated session restoration
- Integration with development tools (git, docker, etc.)
- Docker containerization with MCP service interface
