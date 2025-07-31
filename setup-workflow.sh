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
    local aws_source_dir="${HOME}/.aws"  # Default to current user's .aws directory
    local aws_dest_dir="/home/developer/.aws"
    local current_user=$(whoami)
    
    print_status "Preparing AWS credentials for Docker container..."
    
    # Ensure .aws directory exists in container before copying
    docker exec "$CONTAINER_NAME" mkdir -p "$aws_dest_dir" || true
    
    # Copy AWS config if it exists
    if [ -f "$aws_source_dir/config" ]; then
        docker cp "$aws_source_dir/config" "$CONTAINER_NAME:$aws_dest_dir/config"
        print_status "Copied AWS config to container"
    else
        print_warning "No AWS config file found at $aws_source_dir/config"
    fi
    
    # Copy AWS credentials if they exist
    if [ -f "$aws_source_dir/credentials" ]; then
        docker cp "$aws_source_dir/credentials" "$CONTAINER_NAME:$aws_dest_dir/credentials"
        print_status "Copied AWS credentials to container"
    else
        print_warning "No AWS credentials file found at $aws_source_dir/credentials"
    fi
    
    # Set correct permissions inside the container
    docker exec "$CONTAINER_NAME" bash -c "
        chown -R developer:developer $aws_dest_dir
        chmod 700 $aws_dest_dir
        chmod 600 $aws_dest_dir/config $aws_dest_dir/credentials 2>/dev/null || true
    "
    
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

# Rest of the script remains the same...
# (I'm omitting the rest for brevity, as it would be identical to the previous version)

# Run main function
main "$@"
