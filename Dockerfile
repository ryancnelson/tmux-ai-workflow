# Use Ubuntu 22.04 LTS as base
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update and install essential packages
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    git \
    tmux \
    vim \
    nano \
    htop \
    tree \
    jq \
    # Development tools
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    # Node.js and npm
    nodejs \
    npm \
    # Additional useful tools
    bash-completion \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    # Network tools
    netcat \
    telnet \
    # Process tools
    procps \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest stable Node.js (optional upgrade)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs

# Set up Python environment
RUN python3 -m pip install --upgrade pip setuptools wheel

# Install common Python packages for development
RUN pip3 install \
    requests \
    flask \
    fastapi \
    uvicorn \
    pytest \
    black \
    flake8 \
    mypy \
    jupyter \
    pandas \
    numpy

# Create a non-root user for development
RUN useradd -m -s /bin/bash developer \
    && usermod -aG sudo developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up tmux configuration for better defaults
RUN echo "# Tmux configuration for ai-workflow" > /etc/tmux.conf \
    && echo "set -g mouse on" >> /etc/tmux.conf \
    && echo "set -g default-terminal 'screen-256color'" >> /etc/tmux.conf \
    && echo "set -g history-limit 10000" >> /etc/tmux.conf \
    && echo "set -g base-index 1" >> /etc/tmux.conf \
    && echo "setw -g pane-base-index 1" >> /etc/tmux.conf

# Set up bash configuration
RUN echo "# AI-Workflow bash configuration" >> /etc/bash.bashrc \
    && echo "export PS1='\\u@ai-workflow:\\w\\$ '" >> /etc/bash.bashrc \
    && echo "alias ll='ls -alF'" >> /etc/bash.bashrc \
    && echo "alias la='ls -A'" >> /etc/bash.bashrc \
    && echo "alias l='ls -CF'" >> /etc/bash.bashrc

# Create workspace directory
RUN mkdir -p /workspace && chown developer:developer /workspace

# Switch to developer user
USER developer
WORKDIR /workspace

# Set environment variables
ENV HOME=/home/developer
ENV USER=developer

# Install VSCode server (code-server) for optional remote development
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Expose common development ports
EXPOSE 3000 5000 8000 8080 8443 9000

# Default command starts bash
CMD ["/bin/bash"]
