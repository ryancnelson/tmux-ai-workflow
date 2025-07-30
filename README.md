# AI-Workflow - AI-Collaborative Coding System

A tmux-based system for seamless collaboration between developers and AI assistants, featuring token optimization through local models.

## Quick Start

### Docker Mode (Recommended)
```bash
# Start with Docker (default - provides Ubuntu environment)
chmod +x setup-workflow.sh
./setup-workflow.sh
```

### Native Mode
```bash
# Start without Docker (runs directly on host)
./setup-workflow.sh --native
```

This will either:
- Create a new `ai-workflow` tmux session with the proper 3-pane layout
- Or attach to an existing `ai-workflow` session if one is already running

### Docker Benefits
- **🛡️ Safety**: Commands execute in isolated Ubuntu container
- **🔧 Consistency**: Same Ubuntu 22.04 LTS environment everywhere
- **📦 Pre-configured**: Python, Node.js, build tools, tmux ready to use
- **🔌 Port Forwarding**: Development servers accessible from host
- **💻 VSCode Integration**: Remote development support via dev containers

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
- **Container Isolation**: Docker mode provides additional safety layer

### 🐳 Docker Integration
- **Isolated Execution**: Commands run in Ubuntu container, protecting host system
- **Consistent Environment**: Ubuntu 22.04 LTS with pre-installed development tools
- **Volume Mapping**: Current directory mapped to `/workspace` in container
- **Port Forwarding**: Common development ports (3000, 5000, 8000, 8080, 8443, 9000)
- **VSCode Support**: Full dev container integration for remote development
- **Host File Access**: Claude filesystem tools can still access host files directly

### 🧠 Memory Integration
- **Persistent Context**: Integration with Serena memory system for cross-session context
- **Filesystem Tools**: Safe file operations with comprehensive directory access
- **Documentation**: Self-documenting system via `./tmux-hello` briefing script

## Files

- **`tmux-hello`**: Complete system briefing and AI integration guide
- **`setup-workflow.sh`**: Session setup and management script (supports Docker/native)
- **`Dockerfile`**: Ubuntu 22.04 container with development tools
- **`docker-compose.yml`**: Docker Compose configuration for easy container management
- **`.devcontainer/`**: VSCode dev container configuration
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

### Docker Mode (Recommended)
Once the Docker container and session are set up:
- Commands execute safely in isolated Ubuntu environment
- Claude filesystem tools access host files directly
- Development servers run in container but accessible from host
- Use VSCode with dev containers for full IDE integration

### Command Execution
Work with your AI assistant using natural language commands targeting specific panes:
- "Run `npm test` in the top pane" → Executes in container
- "Check what's running in the left pane" → Shows container processes  
- "Start development server on port 3000" → Accessible from host

### The system handles:
- tmux communication and command execution
- Output parsing and error detection  
- Session recovery and troubleshooting
- Context persistence across sessions
- Container lifecycle management

Run `./tmux-hello` for a complete system briefing and operational guide.

## Benefits

1. **Cost Efficiency**: Significant token savings through local AI integration
2. **Safety**: Docker isolation protects host system + comprehensive safety protocols
3. **Consistency**: Same Ubuntu environment across all machines and developers
4. **Speed**: Local models handle routine tasks instantly
5. **Scalability**: System designed for complex, long-running development workflows
6. **Memory**: Persistent context and documentation across sessions
7. **Tool Availability**: Pre-configured development environment ready to use
8. **VSCode Integration**: Full remote development support with dev containers

## Future Plans

- ✅ **Docker containerization** - Implemented with Ubuntu 22.04 LTS
- ✅ **VSCode integration** - Dev container support added
- MCP service integration (`mcp serve`)
- Enhanced development tool integration
- Expanded local model support beyond phi3/Ollama
- Multi-container support for complex development environments
- Cloud deployment options (AWS, GCP, Azure)
- Team collaboration features
