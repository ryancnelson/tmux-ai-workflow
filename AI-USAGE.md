# AI Assistant Usage Examples

## Running tmux-hello
```bash
./tmux-hello
```
This script provides a complete briefing on the ryan-workflow system state and protocols.

## Example AI Commands (Natural Language)

### Basic Commands
- "Run `ls -la` in the left pane"
- "Execute `git status` in the bottom pane" 
- "Check what's running in the top pane"

### With Timeout for Commands Expected to Finish
- "Run `npm test` in the top pane with a 300 second timeout"
- "Execute `make build` in the left pane with a 120 second timeout"

### File Content Injection (Safe Method)
Instead of:
```bash
cat << EOF > file.txt  # DON'T USE - escaping issues
content here
EOF
```

Use base64 encoding:
```bash
echo "Y29udGVudCBoZXJlCg==" | base64 -d | tee file.txt
```

### Interactive Programs
For mysql, psql, node REPL, etc:
- Don't check for bash prompt first
- Examine current screen state with tmux capture-pane
- Send appropriate commands for the interactive program

## AI Implementation Notes

1. **Always run ./tmux-hello first** to understand current system state
2. **Verify pane prompts** before sending commands
3. **Use appropriate timeouts** based on command type
4. **Monitor command completion** via exit codes and completion markers
5. **Handle errors gracefully** and suggest corrections

## tmux Command Reference for AI

```bash
# Send a command to a specific pane
tmux send-keys -t ryan-workflow:0.0 "command here" Enter

# Capture current pane output
tmux capture-pane -t ryan-workflow:0.1 -p

# Capture last N lines from pane
tmux capture-pane -t ryan-workflow:0.2 -S -20 -p

# Check if session exists
tmux has-session -t ryan-workflow
```

## Pane Mapping
- **Pane 0.0** = LEFT pane (full height, left side)
- **Pane 0.1** = TOP pane (upper right quadrant)  
- **Pane 0.2** = BOTTOM pane (lower right quadrant)
