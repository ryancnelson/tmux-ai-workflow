# AI-Workflow - AI-Collaborative Coding System

A tmux-based system for seamless collaboration between developers and AI assistants, featuring token optimization through local models.

## Quick Start

```bash
# Make the setup script executable and run it
chmod +x setup-workflow.sh
./setup-workflow.sh
```

This will either:
- Create a new `ai-workflow` tmux session with the proper 3-pane layout
- Or attach to an existing `ai-workflow` session if one is already running

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

Each pane has a custom prompt: `ai-workflow-bash:[PANE_NAME] $ `

## AI Assistant Integration

The AI assistant can execute commands using natural language:
- "Run `npm test` in the top pane"
- "Check what's running in the left pane"  
- "Execute `git status` in the bottom pane"

## Key Features

### 🤖 AI Token Optimization
- **Two-Tier Architecture**: High-cost AI (Claude) for strategy, local models (phi3/Ollama) for routine tasks
- **Token Savings**: Local AI handles parsing/translation, Claude focuses on complex reasoning
- **Handoff Pattern**: Natural language → phi3 translation → tmux execution → phi3 cleanup → Claude analysis

### 🛡️ Safety Protocols
- **Base64 Encoding**: Safe text injection without shell escaping issues
- **Heredoc Prevention**: Eliminates common tmux session breaking scenarios
- **Recovery Tools**: Comprehensive error recovery and session management
- **Timeout Handling**: Appropriate timeouts for different command types

### 🧠 Memory Integration
- **Persistent Context**: Integration with Serena memory system for cross-session context
- **Filesystem Tools**: Safe file operations with comprehensive directory access
- **Documentation**: Self-documenting system via `./tmux-hello` briefing script

## Files

- **`tmux-hello`**: Complete system briefing and AI integration guide
- **`setup-workflow.sh`**: Session setup and management script
- **`tmux-recover`**: Recovery tools for stuck sessions
- **`SPECIFICATION.md`**: Complete technical specification
- **`SAFETY-RULES.md`**: Critical safety protocols
- **`AI-USAGE.md`**: AI assistant usage examples
- **`tests/`**: Comprehensive test suite with phi3 simulation

## Research & Development

This system includes completed research into:
- **AI handoff patterns** for cost optimization
- **Token efficiency strategies** using local models
- **Safety protocols** for AI-tmux interaction
- **Real-world testing** with complex build processes (Perl compilation)

See `tests/README.md` for detailed information about the AI handoff pattern and `phi3-simulator.py` for a working demonstration.

## Usage with AI

Once the session is set up, work with your AI assistant using natural language commands targeting specific panes. The system handles:
- tmux communication and command execution
- Output parsing and error detection  
- Session recovery and troubleshooting
- Context persistence across sessions

Run `./tmux-hello` for a complete system briefing and operational guide.

## Benefits

1. **Cost Efficiency**: Significant token savings through local AI integration
2. **Reliability**: Comprehensive safety protocols prevent common session issues
3. **Speed**: Local models handle routine tasks instantly
4. **Scalability**: System designed for complex, long-running development workflows
5. **Memory**: Persistent context and documentation across sessions

## Future Plans

- Docker containerization for portability
- MCP service integration (`mcp serve`)
- Enhanced development tool integration
- Expanded local model support beyond phi3/Ollama
