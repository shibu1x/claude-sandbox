FROM ubuntu:26.04

# Fail the build if any command in a pipe fails (e.g. `curl | bash`),
# instead of silently swallowing it and reporting success.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# When set, use an apt proxy (e.g. apt-cacher-ng) during the build for plain
# HTTP requests only; HTTPS goes DIRECT since apt-cacher-ng can't cache
# encrypted traffic anyway (this also covers deb.nodesource.com, which is
# HTTPS and isn't a package-mirror host the proxy recognizes — apt requests
# to it through the proxy get a 403, silently falling back to Ubuntu's own
# (npm-less) nodejs package).
ARG APT_PROXY_HOST
RUN if [ -n "$APT_PROXY_HOST" ]; then \
      { \
        echo "Acquire::http::Proxy \"http://${APT_PROXY_HOST}:3142\";"; \
        echo "Acquire::https::Proxy \"DIRECT\";"; \
      } > /etc/apt/apt.conf.d/01proxy; \
    fi

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
    bsdextrautils \
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
