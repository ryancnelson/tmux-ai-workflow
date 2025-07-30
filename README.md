# Ryan Workflow - AI-Collaborative Coding System

A tmux-based system for seamless collaboration between developers and AI assistants.

## Quick Start

```bash
# Make the setup script executable and run it
chmod +x setup-workflow.sh
./setup-workflow.sh
```

This will either:
- Create a new `ryan-workflow` tmux session with the proper 3-pane layout
- Or attach to an existing `ryan-workflow` session if one is already running

## Session Layout

```
┌─────────────┬─────────────┐
│             │     TOP     │
│    LEFT     │   (right-   │
│  (full      │   upper)    │
│   height)   ├─────────────┤
│             │   BOTTOM    │
│             │  (right-    │
│             │   lower)    │
└─────────────┴─────────────┘
```

Each pane has a custom prompt: `ryan-workflow-bash:[PANE_NAME] $ `

## AI Assistant Integration

The AI assistant can execute commands using natural language:
- "Run `npm test` in the top pane"
- "Check what's running in the left pane"  
- "Execute `git status` in the bottom pane"

## Features

- **Smart Session Management**: Attaches to existing sessions or creates new ones
- **Custom Prompts**: Each pane clearly labeled for AI identification
- **Mouse Support**: Enabled for easy navigation
- **Safe Text Injection**: Uses base64 encoding to avoid shell escaping issues
- **Timeout Handling**: Appropriate timeouts for different command types
- **Error Recovery**: AI can detect and respond to command failures

## Files

- `SPECIFICATION.md`: Complete technical specification
- `setup-workflow.sh`: Session setup and management script
- `README.md`: This file

## Future Plans

- Docker containerization for portability
- MCP service integration (`mcp serve`)
- Session persistence and restoration
- Enhanced development tool integration

## Usage with AI

Once the session is set up, work with your AI assistant using natural language commands targeting specific panes. The AI will handle tmux communication, command execution, and output parsing automatically.
