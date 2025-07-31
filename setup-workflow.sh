#!/bin/bash

# AI Workflow Setup Script
# Creates or attaches to the ai-workflow tmux session
# Supports both native and Docker execution modes

SESSION_NAME="ai-workflow"
DOCKER_MODE=${AI_WORKFLOW_DOCKER:-true}  # Default to Docker mode
CONTAINER_NAME="ai-workflow-dev"

# ... [previous functions remain the same] ...

start_docker_container() {
    local image_name="ai-workflow:latest"
    local aws_source_dir="${HOME}/.aws"  # Default to current user's .aws directory
    local aws_config_source="${HOME}/.aws/config"
    local aws_credentials_source="${HOME}/.aws/credentials"
    local aws_dest_dir="/home/developer/.aws"
    local aws_config_dest="/home/developer/.aws/config"
    local aws_credentials_dest="/home/developer/.aws/credentials"
    
    print_status "Preparing AWS credentials for Docker container..."
    
    # Ensure .aws directory exists in container
    mkdir -p "$aws_dest_dir"
    
    # Copy AWS config if it exists
    if [ -f "$aws_config_source" ]; then
        cp "$aws_config_source" "$aws_config_dest"
        print_status "Copied AWS config to container"
    else
        print_warning "No AWS config file found at $aws_config_source"
    fi
    
    # Copy AWS credentials if they exist
    if [ -f "$aws_credentials_source" ]; then
        cp "$aws_credentials_source" "$aws_credentials_dest"
        print_status "Copied AWS credentials to container"
    else
        print_warning "No AWS credentials file found at $aws_credentials_source"
    fi
    
    # Ensure correct permissions
    chown -R $(whoami):$(whoami) "$aws_dest_dir"
    chmod 700 "$aws_dest_dir"
    chmod 600 "$aws_config_dest" "$aws_credentials_dest"
    
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
            -v "$aws_dest_dir:/home/developer/.aws:ro" \
            -e TERM=xterm-256color \
            -e AI_WORKFLOW_MODE=docker \
            -e AWS_PROFILE=default \
            -e AWS_REGION=us-east-1 \
            -e CLAUDE_CODE_USE_BEDROCK=1 \
            -e ANTHROPIC_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0 \
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

# ... [rest of the script remains the same] ...

# Modify create_tmux_session to add a step checking AWS configuration
create_tmux_session() {
    local execution_context=$1
    local tmux_command=""
    
    if [ "$execution_context" = "docker" ]; then
        tmux_command="docker exec -it $CONTAINER_NAME"
        print_status "Creating tmux session inside Docker container..."
        
        # Check AWS configuration after container starts
        $tmux_command bash -c 'if [ -f ~/.aws/credentials ]; then 
            echo "AWS Credentials found:"; 
            aws configure list; 
        else 
            echo "WARNING: No AWS credentials configured in container"; 
        fi'
    fi
    
    # ... [rest of the original create_tmux_session function] ...
}

# Run main function
main "$@"
