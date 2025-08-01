# Use Ubuntu 22.04 LTS as base
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    tmux \
    vim \
    python3 \
    python3-pip \
    build-essential \
    sudo \
    gpg \
    awscli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for development
RUN useradd -m -s /bin/bash developer \
    && usermod -aG sudo developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to developer user for Node.js installation
USER developer
WORKDIR /home/developer

# Set up environment for NVM and Node.js
ENV NVM_DIR=/home/developer/.nvm
SHELL ["/bin/bash", "-c"]

# Install NVM (Node Version Manager) as developer user
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Install latest LTS Node.js and npm
RUN source $NVM_DIR/nvm.sh && \
    nvm install --lts && \
    nvm use --lts && \
    echo 'source $NVM_DIR/nvm.sh && nvm use --lts --silent' >> ~/.bashrc

# Install Claude Code CLI
RUN source $NVM_DIR/nvm.sh && nvm use --lts && \
    npm install -g @anthropic-ai/claude-code

# Switch back to root to set up remaining system configurations
USER root

# Fix ownership of home directory and all subdirectories
RUN chown -R developer:developer /home/developer

# Set up basic tmux configuration
RUN echo "set -g mouse on" > /etc/tmux.conf

# Create workspace directory
RUN mkdir -p /workspace && chown developer:developer /workspace

# Create .aws and .claude directories for developer
RUN mkdir -p /home/developer/.aws /home/developer/.claude && \
    chown -R developer:developer /home/developer/.aws /home/developer/.claude

# Switch to developer user
USER developer
WORKDIR /workspace

# Set environment variables for Claude and AWS
ENV HOME=/home/developer
ENV USER=developer
ENV CLAUDE_CODE_USE_BEDROCK=1
ENV AWS_PROFILE=default
ENV AWS_REGION=us-east-1
ENV ANTHROPIC_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0

# Create Claude settings files with configuration
RUN mkdir -p /home/developer/.claude && \
    echo '{"CLAUDE_CODE_USE_BEDROCK":"1","AWS_PROFILE":"default","AWS_REGION":"us-east-1","ANTHROPIC_MODEL":"us.anthropic.claude-sonnet-4-20250514-v1:0"}' > /home/developer/.claude/settings.json && \
    echo '{"permissions":{"allow":[],"deny":[]}}' > /home/developer/.claude/settings.local.json

# Set up user bash configuration
RUN echo "export PS1='developer@ai-workflow:\\w\\$ '" >> ~/.bashrc \
    && echo "cd /workspace 2>/dev/null || true" >> ~/.bashrc \
    && echo "source \$NVM_DIR/nvm.sh && nvm use --lts --silent 2>/dev/null || true" >> ~/.bashrc \
    && echo "echo 'AI-Workflow Environment Ready (Python: \$(python3 --version), Node: \$(node --version 2>/dev/null || echo \"Not available\"))'" >> ~/.bashrc \
    && echo "alias cc='claude'" >> ~/.bashrc

# Expose common development ports
EXPOSE 3000 5000 8000 8080

# Default command starts bash
CMD ["/bin/bash"]
