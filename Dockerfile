FROM ubuntu:26.04

# Install base tools commonly needed inside the sandbox
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    build-essential \
    less \
    procps \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (needed for the Claude Code CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Ubuntu ships a default non-root "ubuntu" user (uid/gid 1000); reuse it
ARG USERNAME=ubuntu

RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Persist Claude Code config/auth across container restarts (mounted as a volume)
RUN mkdir -p /home/$USERNAME/.claude && chown -R $USERNAME:$USERNAME /home/$USERNAME

WORKDIR /workspace
RUN chown $USERNAME:$USERNAME /workspace

USER $USERNAME

ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
