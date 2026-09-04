# WSL + dsh troubleshooting

When the agent runs in WSL and the browser is on Windows, failures are often cross-system networking—not dsh itself. Match symptoms to tools; avoid blind restarts.

Full fault tree (中文): [TROUBLESHOOTING.zh.md](./TROUBLESHOOTING.zh.md).

## Quick map

| Symptom | Tool first | Plugin |
|---------|------------|--------|
| DeepSeek Search / `TypeError: fetch failed` | `net_doctor` (confirm **dsh process** `NODE_USE_ENV_PROXY=1` + proxy OPEN) → `check-dsh-health.sh` / `restart-dsh-web.sh` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| Local LLM unreachable / ctx / HTTP 404 on /v1/models | `host_reach` (`apiReady` / `ctxReports`) → optional `docker_doctor` | [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) |
| settings `contextWindow` > Ollama `num_ctx` | `host_reach` → lower settings or raise `OLLAMA_NUM_CTX` | dsh-wsl-hostsvc |
| DeepSeek API / npm timeout | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| ModelScope / Hugging Face | `net_doctor` target=`registry` | dsh-wsl-net |
| git push / GitHub 401 | `github_app_hint` + `cred_doctor` | github + cred |
| DNS weirdness | `dns_doctor` | [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) |
| WSL vs Windows A-record mismatch for same host | `dns_doctor` (then `net_doctor` / `wslconfig_hint`) | dsh-wsl-dns |
| TLS clock skew / post-sleep skew / GitHub App JWT oddities | `clock_doctor` (then `wsl --shutdown` if needed) | [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) |
| Workspace on Desktop/Downloads (`/mnt/c/...`) | `wsl_workspace` + `mnt_doctor` | [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) |
| Browser cannot open WSL dsh web | `check-dsh-health` → `port_doctor` → `restart-dsh-web` → (LAN only) `wsl_expose`; see §0 | [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) / expose |
| `CONTEXT_WINDOW_EXCEEDED` | Align settings `contextWindow` with Ollama `num_ctx` (≥32768 when many plugins) | hostsvc + settings |
| Tools behave like an old build / plugin missing | `bash scripts/check-plugin-versions.sh` → `dsh plugin add` + `restart-dsh-web.sh` | [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit) |

## 0. Windows browser ↔ WSL dsh (required)

dsh **must not** bind `--host 0.0.0.0`; it listens on `127.0.0.1:3080` only. Use the relay on Windows:

```text
ERR_CONNECTION_REFUSED / blank page
  → bash scripts/check-dsh-health.sh
  → port_doctor on 3080/3081 (uiPlaybook)
  → bash scripts/restart-dsh-web.sh
  → Open http://127.0.0.1:3081/ (not :3000; not bare :3080 unless mirrored verified)
  → wsl_expose only for LAN / non-local UI — no netsh portproxy for local dsh UI

ERR_CONNECTION_RESET (relay up, dsh down)
  → Same: health → port_doctor → restart; confirm both 3080 and 3081 are listening

/api 403 (Host rewrite broke Origin)
  → Do not rewrite Host; keep Host: 127.0.0.1:3081 + --trusted-host
```

## Recommended install for local LLM

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=llm bash
```

Then run [`scripts/restart-dsh-web.sh`](../scripts/restart-dsh-web.sh) and open a **new session**.
