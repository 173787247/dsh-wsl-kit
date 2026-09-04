# WSL + dsh troubleshooting

When the agent runs in WSL and the browser is on Windows, failures are often cross-system networking—not dsh itself. Match symptoms to tools; avoid blind restarts.

Full fault tree (中文): [TROUBLESHOOTING.zh.md](./TROUBLESHOOTING.zh.md).

## Quick map

| Symptom | Tool first | Plugin |
|---------|------------|--------|
| DeepSeek Search / `TypeError: fetch failed` | `net_doctor` (need `NODE_USE_ENV_PROXY=1` + proxy port OPEN) → `restart-dsh-web.sh` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| Local LLM unreachable / ctx errors | `host_reach` | [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) |
| DeepSeek API / npm timeout | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| ModelScope / Hugging Face | `net_doctor` target=`registry` | dsh-wsl-net |
| git push / GitHub 401 | `github_app_hint` + `cred_doctor` | github + cred |
| DNS weirdness | `dns_doctor` | [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) |
| WSL vs Windows A-record mismatch for same host | `dns_doctor` (then `net_doctor` / `wslconfig_hint`) | dsh-wsl-dns |
| TLS clock skew / post-sleep skew / GitHub App JWT oddities | `clock_doctor` (then `wsl --shutdown` if needed) | [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) |
| Workspace on Desktop/Downloads (`/mnt/c/...`) | `wsl_workspace` + `mnt_doctor` | [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) |
| Browser cannot open WSL dsh web | See §0; then `wsl_expose` | dsh-wsl-expose |
| `CONTEXT_WINDOW_EXCEEDED` | Align settings `contextWindow` with Ollama `num_ctx` (≥32768 when many plugins) | hostsvc + settings |

## 0. Windows browser ↔ WSL dsh (required)

dsh **must not** bind `--host 0.0.0.0`; it listens on `127.0.0.1:3080` only. Use the relay on Windows:

```text
ERR_CONNECTION_REFUSED / blank page
  → Wrong port (:3000 is GenericAgent) or only :3080 open?
  → bash scripts/restart-dsh-web.sh
  → Open http://127.0.0.1:3081/

ERR_CONNECTION_RESET (relay up, dsh down)
  → Same restart; confirm both 3080 and 3081 are listening

/api 403 (Host rewrite broke Origin)
  → Do not rewrite Host; keep Host: 127.0.0.1:3081 + --trusted-host
```

## Recommended install for local LLM

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=llm bash
```

Then run [`scripts/restart-dsh-web.sh`](../scripts/restart-dsh-web.sh) and open a **new session**.
