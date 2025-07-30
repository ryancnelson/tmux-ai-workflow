#!/bin/bash

# AI Workflow Setup Script
# Creates or attaches to the ai-workflow tmux session
# Supports both native and Docker execution modes

SESSION_NAME="ai-workflow"
DOCKER_MODE=${AI_WORKFLOW_DOCKER:-true}  # Default to Docker mode
CONTAINER_NAME="ai-workflow-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[AI-Workflow]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Success]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[Warning]${NC} $1"
}

print_error() {
    echo -e "${RED}[Error]${NC} $1"
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        return 1
    fi
    
    return 0
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        return 0
    elif docker compose version &> /dev/null; then
        return 0
    else
        print_warning "Docker Compose not found, will use docker run instead"
        return 1
    fi
}

# Function to build Docker image if needed
build_docker_image() {
    local image_name="ai-workflow:latest"
    
    print_status "Checking if Docker image exists..."
    
    if ! docker image inspect "$image_name" &> /dev/null; then
        print_status "Building ai-workflow Docker image..."
        if docker build -t "$image_name" .; then
            print_success "Docker image built successfully"
        else
            print_error "Failed to build Docker image"
            return 1
        fi
    else
        print_status "Docker image already exists"
    fi
    
    return 0
}

# Function to start Docker container
start_docker_container() {
    local image_name="ai-workflow:latest"
    
    # Check if container is already running
    if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        print_status "Container $CONTAINER_NAME is already running"
        return 0
    fi
    
    # Check if container exists but is stopped
    if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        print_status "Starting existing container $CONTAINER_NAME..."
        docker start "$CONTAINER_NAME"
        return 0
    fi
    
    # Create and start new container
    print_status "Creating and starting new container $CONTAINER_NAME..."
    
    # Use docker-compose if available, otherwise use docker run
    if check_docker_compose; then
        docker-compose up -d
    else
        docker run -d \
            --name "$CONTAINER_NAME" \
            --network host \
            -v "$(pwd):/workspace" \
            -v "$HOME/.gitconfig:/home/developer/.gitconfig:ro" 2>/dev/null || true \
            -v "$HOME/.ssh:/home/developer/.ssh:ro" 2>/dev/null || true \
            -e TERM=xterm-256color \
            -e AI_WORKFLOW_MODE=docker \
            --stdin --tty \
            "$image_name" \
            sleep infinity
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Container started successfully"
        return 0
    else
        print_error "Failed to start container"
        return 1
    fi
}

# Function to set up custom prompt in a pane
setup_pane_prompt() {
    local pane_name=$1
    local pane_target=$2
    local execution_context=$3
    
    print_status "Setting up prompt for $pane_name pane..."
    
    if [ "$execution_context" = "docker" ]; then
        # Set the custom PS1 prompt with Docker indicator
        tmux send-keys -t "$pane_target" "export PS1='ai-workflow-bash:$pane_name(🐳) \$ '" Enter
    else
        # Set the custom PS1 prompt for native execution
        tmux send-keys -t "$pane_target" "export PS1='ai-workflow-bash:$pane_name \$ '" Enter
    fi
    
    # Clear the screen for a clean start
    tmux send-keys -t "$pane_target" "clear" Enter
    
    # Send a comment to help identify the pane
    if [ "$execution_context" = "docker" ]; then
        tmux send-keys -t "$pane_target" "# $pane_name pane ready for ai-workflow (Docker: Ubuntu)" Enter
    else
        tmux send-keys -t "$pane_target" "# $pane_name pane ready for ai-workflow (Native: $(uname -s))" Enter
    fi
}

# Function to create tmux session
create_tmux_session() {
    local execution_context=$1
    local tmux_command=""
    
    if [ "$execution_context" = "docker" ]; then
        tmux_command="docker exec -it $CONTAINER_NAME"
        print_status "Creating tmux session inside Docker container..."
    else
        print_status "Creating native tmux session..."
    fi
    
    # Create new session (detached)
    if [ "$execution_context" = "docker" ]; then
        $tmux_command tmux new-session -d -s "$SESSION_NAME"
    else
        tmux new-session -d -s "$SESSION_NAME"
    fi
    
    # Split horizontally (left and right)
    if [ "$execution_context" = "docker" ]; then
        $tmux_command tmux split-window -h -t "$SESSION_NAME"
        # Split the right pane vertically (top and bottom)
        $tmux_command tmux split-window -v -t "$SESSION_NAME:0.1"
        # Enable mouse mode
        $tmux_command tmux set-option -t "$SESSION_NAME" mouse on
    else
        tmux split-window -h -t "$SESSION_NAME"
        tmux split-window -v -t "$SESSION_NAME:0.1"
        tmux set-option -t "$SESSION_NAME" mouse on
    fi
    
    # Set up custom prompts for each pane
    # Pane 0 = left, Pane 1 = top-right, Pane 2 = bottom-right
    if [ "$execution_context" = "docker" ]; then
        # For Docker, we need to send commands to the container
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.0" "export PS1='ai-workflow-bash:left(🐳) \$ '" Enter
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.0" "clear" Enter
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.0" "# left pane ready for ai-workflow (Docker: Ubuntu)" Enter
        
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.1" "export PS1='ai-workflow-bash:top(🐳) \$ '" Enter
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.1" "clear" Enter
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.1" "# top pane ready for ai-workflow (Docker: Ubuntu)" Enter
        
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.2" "export PS1='ai-workflow-bash:bottom(🐳) \$ '" Enter
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.2" "clear" Enter
        $tmux_command tmux send-keys -t "$SESSION_NAME:0.2" "# bottom pane ready for ai-workflow (Docker: Ubuntu)" Enter
    else
        setup_pane_prompt "left" "$SESSION_NAME:0.0" "native"
        setup_pane_prompt "top" "$SESSION_NAME:0.1" "native"
        setup_pane_prompt "bottom" "$SESSION_NAME:0.2" "native"
    fi
    
    # Select the left pane as default
    if [ "$execution_context" = "docker" ]; then
        $tmux_command tmux select-pane -t "$SESSION_NAME:0.0"
    else
        tmux select-pane -t "$SESSION_NAME:0.0"
    fi
}

# Function to attach to tmux session
attach_tmux_session() {
    local execution_context=$1
    
    if [ "$execution_context" = "docker" ]; then
        print_success "Attaching to ai-workflow session in Docker container..."
        docker exec -it "$CONTAINER_NAME" tmux attach-session -t "$SESSION_NAME"
    else
        print_success "Attaching to native ai-workflow session..."
        tmux attach-session -t "$SESSION_NAME"
    fi
}

# Function to check if tmux session exists
session_exists() {
    local execution_context=$1
    
    if [ "$execution_context" = "docker" ]; then
        # Check if container is running first
        if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            return 1
        fi
        # Check if tmux session exists in container
        docker exec "$CONTAINER_NAME" tmux has-session -t "$SESSION_NAME" 2>/dev/null
    else
        tmux has-session -t "$SESSION_NAME" 2>/dev/null
    fi
}

# Main execution logic
main() {
    print_status "AI-Workflow Setup Starting..."
    
    # Check command line arguments
    case "${1:-}" in
        --native)
            DOCKER_MODE=false
            print_status "Native mode requested"
            ;;
        --docker)
            DOCKER_MODE=true
            print_status "Docker mode requested"
            ;;
        --help|-h)
            echo "AI-Workflow Setup Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --docker    Use Docker mode (default)"
            echo "  --native    Use native mode (run tmux directly on host)"
            echo "  --help,-h   Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  AI_WORKFLOW_DOCKER=true|false  Override default Docker mode"
            echo ""
            exit 0
            ;;
    esac
    
    # Determine execution mode
    if [ "$DOCKER_MODE" = "true" ]; then
        print_status "Using Docker execution mode"
        
        # Check Docker availability
        if ! check_docker; then
            print_warning "Docker not available, falling back to native mode"
            DOCKER_MODE=false
        else
            # Build image and start container
            if ! build_docker_image; then
                print_error "Failed to prepare Docker environment"
                exit 1
            fi
            
            if ! start_docker_container; then
                print_error "Failed to start Docker container"
                exit 1
            fi
        fi
    fi
    
    if [ "$DOCKER_MODE" = "false" ]; then
        print_status "Using native execution mode"
    fi
    
    # Check if session already exists
    local execution_context
    if [ "$DOCKER_MODE" = "true" ]; then
        execution_context="docker"
    else
        execution_context="native"
    fi
    
    if session_exists "$execution_context"; then
        print_status "ai-workflow session already exists. Attaching..."
        attach_tmux_session "$execution_context"
    else
        print_status "Creating new ai-workflow session..."
        create_tmux_session "$execution_context"
        
        print_success "ai-workflow session created successfully!"
        echo ""
        if [ "$execution_context" = "docker" ]; then
            echo "Environment: Docker (Ubuntu 22.04 LTS)"
            echo "Container: $CONTAINER_NAME"
            echo "Workspace: /workspace (mapped from $(pwd))"
        else
            echo "Environment: Native ($(uname -s))"
            echo "Workspace: $(pwd)"
        fi
        echo ""
        echo "Panes configured:"
        echo "  - Left pane: full height, left side"
        echo "  - Top pane: upper right quadrant"
        echo "  - Bottom pane: lower right quadrant"
        echo ""
        
        attach_tmux_session "$execution_context"
    fi
}

# Run main function
main "$@"
