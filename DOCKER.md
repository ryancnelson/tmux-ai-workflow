# Docker Integration Guide

## Overview

AI-Workflow now includes full Docker containerization, providing a safe, consistent Ubuntu development environment while maintaining full integration with Claude filesystem tools.

## Quick Start

### Automatic Docker Mode (Recommended)
```bash
# Default behavior - automatically uses Docker if available
./setup-workflow.sh
```

### Manual Mode Selection
```bash
# Force Docker mode
./setup-workflow.sh --docker

# Force native mode (no Docker)
./setup-workflow.sh --native
```

## Architecture

### Container Environment
- **Base Image**: Ubuntu 22.04 LTS
- **User**: `developer` (non-root with sudo access)
- **Working Directory**: `/workspace` (mapped from host `pwd`)
- **Network**: Host networking for easy port access

### Pre-installed Tools
- **Languages**: Python 3.10+, Node.js LTS
- **Development**: git, tmux, vim, nano, build-essential
- **Python Packages**: requests, flask, fastapi, pytest, black, flake8, jupyter
- **Utilities**: curl, wget, jq, htop, tree
- **Optional**: code-server (VSCode in browser)

### Volume Mappings
- `$(pwd):/workspace` - Current directory to container workspace
- `~/.gitconfig:/home/developer/.gitconfig:ro` - Git configuration (read-only)
- `~/.ssh:/home/developer/.ssh:ro` - SSH keys for git operations (read-only)

### Port Forwarding
- **3000**: React/Next.js development server
- **5000**: Flask default port
- **8000**: Python HTTP server / Django
- **8080**: Alternative HTTP server
- **8443**: VSCode server (code-server)
- **9000**: Alternative development server

## Usage Patterns

### Basic Development Workflow
1. **Start the system**: `./setup-workflow.sh`
2. **Work in panes**: Commands execute safely in Ubuntu container
3. **File access**: Claude filesystem tools access host files directly
4. **Port access**: Development servers accessible from host browser

### VSCode Integration

#### Method 1: Dev Containers Extension
1. Install "Dev Containers" extension in VSCode
2. Open project folder in VSCode
3. Command palette: "Dev Containers: Reopen in Container"
4. VSCode runs inside the container with full tool access

#### Method 2: Code-Server (Browser-based)
1. Start ai-workflow Docker container
2. Run inside container: `code-server --bind-addr 0.0.0.0:8443`
3. Access via browser: `http://localhost:8443`
4. Password shown in terminal output

### AI Command Examples

```bash
# These commands execute in the Ubuntu container:
"Install npm packages in the top pane"
"Run pytest in the bottom pane" 
"Start Flask development server on port 5000 in left pane"
"Check Python version in all panes"

# Meanwhile, Claude filesystem tools work on host:
filesystem:read_file('/host/path/to/file.py')
filesystem:write_file('/host/path/new_file.py', 'content')
```

## Container Management

### Manual Container Operations
```bash
# Check container status
docker ps | grep ai-workflow-dev

# Enter running container
docker exec -it ai-workflow-dev bash

# View container logs
docker logs ai-workflow-dev

# Stop container
docker stop ai-workflow-dev

# Remove container (data in workspace persists)
docker rm ai-workflow-dev

# Rebuild image after Dockerfile changes
docker build -t ai-workflow:latest .
```

### Docker Compose Operations
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up --build -d
```

## Troubleshooting

### Docker Not Available
- **Symptom**: "Docker is not installed or not in PATH"
- **Solution**: Install Docker Desktop or Docker Engine
- **Fallback**: System automatically falls back to native mode

### Container Build Fails
- **Check**: Docker daemon is running
- **Try**: `docker system prune` to clean up space
- **Alternative**: Pull pre-built image when available

### Port Conflicts
- **Issue**: Port already in use on host
- **Solution**: Modify `docker-compose.yml` port mappings
- **Check**: `lsof -i :3000` to see what's using a port

### Permission Issues
- **SSH keys**: Ensure `~/.ssh` has correct permissions (700 for directory, 600 for files)
- **Git config**: Check `~/.gitconfig` exists and is readable
- **Container user**: Commands run as `developer` user, not root

### tmux Session Issues
- **Docker restart**: tmux sessions don't persist across container restarts
- **Recovery**: Run `./setup-workflow.sh` again to recreate session
- **Persistence**: Use `tmux new-session -d -s persistent` for important sessions

## Security Considerations

### Container Isolation
- Commands execute in isolated Ubuntu environment
- Host system protected from potentially harmful operations
- Network access controlled through Docker networking

### File System Access
- Container only has access to current directory via volume mount
- Claude filesystem tools access full host filesystem (by design)
- No access to sensitive host directories like `/etc`, `/root`

### Resource Limits
```yaml
# Add to docker-compose.yml to limit resources:
mem_limit: 4g
cpus: 2.0
```

## Advanced Configuration

### Custom Development Tools
Add to `Dockerfile`:
```dockerfile
# Install additional tools
RUN apt-get update && apt-get install -y \
    your-favorite-tool \
    another-tool
```

### Environment Variables
Set in `docker-compose.yml`:
```yaml
environment:
  - CUSTOM_VAR=value
  - DEVELOPMENT_MODE=true
```

### Additional Volume Mounts
```yaml
volumes:
  - ./data:/workspace/data
  - ~/.aws:/home/developer/.aws:ro
```

## Integration with AI Workflow

### Claude Filesystem Tools
- **Host Access**: `filesystem:read_file('/host/absolute/path')`
- **Container Visibility**: Files appear in `/workspace` inside container
- **Two-way Sync**: Changes visible both in container and host

### Serena Memory System
- Memories stored on host system
- Accessible across container restarts
- Container mode noted in context

### Safety Protocols
- All existing safety rules apply
- Additional container isolation layer
- Base64 encoding still required for complex file operations

This Docker integration provides the perfect balance of safety and functionality for AI-assisted development!
