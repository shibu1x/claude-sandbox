# claude_sandbox

Docker-based sandbox environment for running Claude Code.

## Usage

```bash
# Build and start the container
docker compose run --rm claude_sandbox

# Or build only
docker compose build
```

Place the project you want Claude Code to work on inside `./workspace` — it is
mounted into the container at `/workspace`. Claude Code auth/config persists
across runs via the `claude_config` named volume.

See CLAUDE.md for project conventions.
