#!/bin/bash

# Ryan Workflow Setup Script
# Creates or attaches to the ryan-workflow tmux session

SESSION_NAME="ryan-workflow"

# Function to set up custom prompt in a pane
setup_pane_prompt() {
    local pane_name=$1
    local pane_target=$2
    
    echo "Setting up prompt for $pane_name pane..."
    
    # Set the custom PS1 prompt
    tmux send-keys -t "$pane_target" "export PS1='ryan-workflow-bash:$pane_name \$ '" Enter
    
    # Clear the screen for a clean start
    tmux send-keys -t "$pane_target" "clear" Enter
    
    # Send a comment to help identify the pane
    tmux send-keys -t "$pane_target" "# $pane_name pane ready for ryan-workflow" Enter
}

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "ryan-workflow session already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
else
    echo "Creating new ryan-workflow session..."
    
    # Create new session (detached)
    tmux new-session -d -s "$SESSION_NAME"
    
    # Split horizontally (left and right)
    tmux split-window -h -t "$SESSION_NAME"
    
    # Split the right pane vertically (top and bottom)
    tmux split-window -v -t "$SESSION_NAME:0.1"
    
    # Enable mouse mode
    tmux set-option -t "$SESSION_NAME" mouse on
    
    # Set up custom prompts for each pane
    # Pane 0 = left, Pane 1 = top-right, Pane 2 = bottom-right
    setup_pane_prompt "left" "$SESSION_NAME:0.0"
    setup_pane_prompt "top" "$SESSION_NAME:0.1"
    setup_pane_prompt "bottom" "$SESSION_NAME:0.2"
    
    # Select the left pane as default
    tmux select-pane -t "$SESSION_NAME:0.0"
    
    echo "ryan-workflow session created successfully!"
    echo "Panes configured:"
    echo "  - Left pane: full height, left side"
    echo "  - Top pane: upper right quadrant"
    echo "  - Bottom pane: lower right quadrant"
    echo ""
    echo "Attaching to session..."
    
    # Attach to the session
    tmux attach-session -t "$SESSION_NAME"
fi
