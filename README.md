# llm-stack

A small local LLM stack: **[ollama](https://ollama.com)** (model runtime) +
**[open-webui](https://github.com/open-webui/open-webui)** (chat UI). Two ways to run it:

| Path | Best for | Entry point |
|------|----------|-------------|
| **Docker Compose** | Linux, NVIDIA/AMD GPUs | `./compose.sh` |
| **Nix (native)** | macOS / Apple Silicon (native Metal) | `nix run` |

---

## Native deployment (Nix) — macOS / Apple Silicon

Docker on Apple Silicon can't give ollama GPU (Metal) access, so this path runs both
services **directly on the host** under [`process-compose`](https://github.com/F1bonacc1/process-compose),
wired declaratively with [services-flake](https://github.com/juspay/services-flake).
Native ollama uses Metal automatically — no configuration needed.

- **ollama** comes from nixpkgs (no global install).
- **open-webui** runs the latest release straight from PyPI via `uvx` (no clone, no Node build).
- Data persists in `./.data/ollama` and `./.data/open-webui` (same layout as the Docker path).

### Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
  (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`).

### Commands

| Action | Command |
|--------|---------|
| Start everything (interactive TUI) | `nix run` |
| Start detached (background) | `nix run . -- up -D` |
| Status of all processes | `process-compose process list` |
| **Restart one service** | `process-compose process restart open-webui` |
| **Stop one service** | `process-compose process stop ollama` |
| **Start one service** | `process-compose process start ollama` |
| Stop everything | `process-compose down` |

`process-compose`, `ollama`, `uv` and `git` are available inside `nix develop` if you
want them on your PATH for ad-hoc control.

Open the UI at **http://localhost:3000**. The API is on **http://localhost:11434**.
Override the UI port with `WEBUI_PORT`.

### Notes

- **First run** downloads Python 3.11 + open-webui via `uvx`, and any ollama models
  you pull — subsequent starts are fast and offline.
- **GPU:** the Docker `--gpu` / nvidia / amd extensions are Linux-only. On Apple
  Silicon, Metal is automatic; confirm with `ollama ps` (should show `100% GPU`).

---

## Docker deployment (Linux / NVIDIA / AMD)

Unchanged. `./compose.sh` wraps `docker compose` with sensible defaults:

```bash
./compose.sh up                  # open-webui only (assumes external ollama)
./compose.sh --ollama up         # open-webui + ollama (CPU)
./compose.sh --ollama --gpu up   # + auto-detected GPU (nvidia/amd)
./compose.sh --ollama down       # tear down
```
