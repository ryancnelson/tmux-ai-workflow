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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for development
RUN useradd -m -s /bin/bash developer \
    && usermod -aG sudo developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up basic tmux configuration
RUN echo "set -g mouse on" > /etc/tmux.conf

# Create workspace directory
RUN mkdir -p /workspace && chown developer:developer /workspace

# Switch to developer user
USER developer
WORKDIR /workspace

# Set environment variables
ENV HOME=/home/developer
ENV USER=developer

# Basic Python setup
RUN python3 -m pip install --user pip --upgrade

# Set up user bash configuration
RUN echo "export PS1='developer@ai-workflow:\\w\\$ '" >> ~/.bashrc \
    && echo "cd /workspace 2>/dev/null || true" >> ~/.bashrc \
    && echo "echo 'AI-Workflow Environment Ready (Python: \$(python3 --version), Node: \$(node --version))'" >> ~/.bashrc

# Expose common development ports
EXPOSE 3000 5000 8000 8080

# Default command starts bash
CMD ["/bin/bash"]
