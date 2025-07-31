# Use Ubuntu 22.04 LTS as base
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential packages only
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    tmux \
    vim \
    python3 \
    python3-pip \
    nodejs \
    npm \
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

# Install claude-code (assuming NPM package)
RUN npm install -g claude-code

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
ENV PATH="/home/developer/.local/bin:${PATH}"
ENV CLAUDE_CODE_USE_BEDROCK=1
ENV AWS_PROFILE=default
ENV AWS_REGION=us-east-1
ENV ANTHROPIC_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0

# Basic Python setup (install to user directory)
RUN python3 -m pip install --user pip --upgrade

# Create Claude settings files with configuration
RUN mkdir -p /home/developer/.claude && \
    echo '{"CLAUDE_CODE_USE_BEDROCK":"1","AWS_PROFILE":"default","AWS_REGION":"us-east-1","ANTHROPIC_MODEL":"us.anthropic.claude-sonnet-4-20250514-v1:0"}' > /home/developer/.claude/settings.json && \
    echo '{"permissions":{"allow":[],"deny":[]}}' > /home/developer/.claude/settings.local.json

# Set up user bash configuration
RUN echo "export PS1='developer@ai-workflow:\\w\\$ '" >> ~/.bashrc \
    && echo "cd /workspace 2>/dev/null || true" >> ~/.bashrc \
    && echo "echo 'AI-Workflow Environment Ready (Python: \$(python3 --version), Node: \$(node --version))'" >> ~/.bashrc \
    && echo "alias claude='claude-code'" >> ~/.bashrc

# Expose common development ports
EXPOSE 3000 5000 8000 8080

# Default command starts bash
CMD ["/bin/bash"]
