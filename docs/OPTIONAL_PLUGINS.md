# Optional Linux / local capability plugins

> These are **not** in `install.sh` / Daily. Install as needed when the browser is on Windows and the agent is in WSL.  
> Each repo homepage is Chinese `README.md`; English is `README.en.md`.

Also listed in the main [README.md](../README.md) optional table and Beyond section.

## Catalog

| Plugin | Ver | Summary |
|--------|-----|---------|
| [dsh-wsl-ollama](https://github.com/173787247/dsh-wsl-ollama) | 0.1.0 | Local Ollama: status / list / chat / embed. |
| [dsh-wsl-llamacpp](https://github.com/173787247/dsh-wsl-llamacpp) | 0.1.0 | OpenAI-compatible client for llama.cpp / Unsloth Desktop (default :8080). |
| [dsh-wsl-vllm](https://github.com/173787247/dsh-wsl-vllm) | 0.1.0 | OpenAI-compatible vLLM client (default :8000). |
| [dsh-wsl-vecmem](https://github.com/173787247/dsh-wsl-vecmem) | 0.1.0 | Tiny local vector memory via Ollama embeddings + `~/.dsh/vecmem`. |
| [dsh-wsl-media](https://github.com/173787247/dsh-wsl-media) | 0.2.0 | Local media/doc pipeline: probe, extract, thumbnail, PDF, ASR, pandoc, OCR, exif. |
| [dsh-wsl-search](https://github.com/173787247/dsh-wsl-search) | 0.2.0 | Sandboxed ripgrep / fd / ast-grep. |
| [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) | 0.2.0 | Read-only pass / age secrets (requires allowPrefixes). |
| [dsh-wsl-struct](https://github.com/173787247/dsh-wsl-struct) | 0.1.0 | Sandboxed jq / yq / read-only sqlite3. |
| [dsh-wsl-git](https://github.com/173787247/dsh-wsl-git) | 0.1.0 | Capped git status / diff --stat (no full patches). |
| [dsh-wsl-tmux](https://github.com/173787247/dsh-wsl-tmux) | 0.1.0 | Read-only tmux list + capture-pane. |
| [dsh-wsl-compose](https://github.com/173787247/dsh-wsl-compose) | 0.1.0 | docker compose ps/logs; up/down double-gated. |
| [dsh-wsl-systemd](https://github.com/173787247/dsh-wsl-systemd) | 0.1.0 | systemd --user read-only list/show/journal. |
| [dsh-wsl-k8s](https://github.com/173787247/dsh-wsl-k8s) | 0.1.0 | Read-only kubectl get / describe / logs. |
| [dsh-wsl-helm](https://github.com/173787247/dsh-wsl-helm) | 0.1.0 | Read-only helm list/status/history. |
| [dsh-wsl-terraform](https://github.com/173787247/dsh-wsl-terraform) | 0.1.0 | terraform/tofu plan summary + state list (never apply). |
| [dsh-wsl-rclone](https://github.com/173787247/dsh-wsl-rclone) | 0.1.0 | Read-only rclone listremotes / lsf / about. |
| [dsh-wsl-db](https://github.com/173787247/dsh-wsl-db) | 0.1.0 | Read-only psql + redis-cli probes. |
| [dsh-wsl-glab](https://github.com/173787247/dsh-wsl-glab) | 0.1.0 | Read-only glab MR/issue/ci status. |
| [dsh-wsl-playwright](https://github.com/173787247/dsh-wsl-playwright) | 0.1.0 | Headless Playwright fetch (title + body text) in WSL. |
| [dsh-wsl-mail](https://github.com/173787247/dsh-wsl-mail) | 0.1.0 | Mail list/search via himalaya / notmuch (no send). |
| [dsh-wsl-cal](https://github.com/173787247/dsh-wsl-cal) | 0.1.0 | Read-only khal calendar list. |
| [dsh-wsl-pkg](https://github.com/173787247/dsh-wsl-pkg) | 0.1.0 | Dependency tree summaries: npm / pip / cargo. |

Also (other tracks / main README): `dsh-wsl-jev` / `obsidian` / `im`.

## Batch-link into web profile

```sh
bash scripts/link-linux-plugins.sh
```

Override the list with `DSH_LINK_PLUGINS` (space-separated).

## License

MIT (same as individual plugins).
