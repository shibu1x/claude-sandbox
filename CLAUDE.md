# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo builds and publishes a Docker image that packages the Claude Code
CLI itself into a disposable, sandboxed environment. The image is meant to be
run against an arbitrary project directory (bind-mounted at `/workspace`), so
Claude Code can operate inside the container instead of directly on the host.

## Commands

**Local build + run (dev loop):**
```bash
docker compose build
docker compose run --rm claude-sandbox
```
Uses `./workspace` (bind-mounted to `/workspace`) as the project Claude Code
operates on. Claude Code auth/config persists across runs via the
`claude-config` named volume.

**Multi-arch build & publish** (`Taskfile.yaml`, requires `task`):
```bash
task build
```
Builds `linux/amd64` (via the `AMD64_BUILDER` buildx builder) and
`linux/arm64` images and pushes both, then combines them into a single
manifest tagged `${REGISTRY}/${APP_NAME}:latest` via
`docker buildx imagetools create`. Requires a `.env` file (see
`.env.example`) defining `APP_NAME`, `REGISTRY`, and `AMD64_BUILDER`.

**Run the published image against the current directory** (`run.sh`):
```bash
./run.sh
```
Pulls `cr.quud.net/claude-sandbox:latest` and bind-mounts `$(pwd)` (not
`./workspace`) to the *same absolute path* inside the container — not a fixed
`/workspace` — this is the "install once, use anywhere" entry point, as
opposed to the compose-based dev loop above. Mounting at the real host path
(rather than a fixed `/workspace`) matters because Claude Code keys its
per-project session history/memory (`~/.claude/projects/<encoded-cwd>`) off
the container's cwd path; a fixed `/workspace` would make every project run
through `run.sh` collide under the same key despite `~/claude-sandbox`
(mounted to `/home/ubuntu`) being shared across all of them for auth
persistence.

## Architecture

- **Base image**: `ubuntu:26.04`. Node.js is not present on this base and is
  installed via the NodeSource setup script (`setup_24.x`) before `npm
  install -g @anthropic-ai/claude-code`.
- **User**: runs as Ubuntu's built-in `ubuntu` user (uid/gid 1000) rather than
  creating a new one, with passwordless `sudo` added. Claude Code's config
  directory (`/home/ubuntu/.claude`) is where the `claude_config` volume /
  auth persistence must be mounted — if the base image or user is ever
  changed, this path has to move with it.
- **Entrypoint**: `ENTRYPOINT ["claude", "--dangerously-skip-permissions"]` —
  the container always launches Claude Code in YOLO mode (permission prompts
  skipped). This is intentional: the whole point of the container is to be
  the sandbox boundary, so Claude Code doesn't need to re-prompt for
  permission inside it. Any extra args passed to `docker run`/`docker compose
  run` are appended after this.
- **Two mounting conventions coexist** and are not interchangeable:
  `compose.yaml` mounts `./workspace` (a directory inside this repo, used for
  local dev/testing of the image), while `run.sh` mounts the *caller's*
  current directory (the real usage pattern once the image is published).
