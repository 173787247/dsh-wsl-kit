# WSL + dsh troubleshooting

When the agent runs in WSL and the browser is on Windows, failures are often cross-system networking—not dsh itself. Match symptoms to tools; avoid blind restarts.

Chinese fault tree: [TROUBLESHOOTING.zh.md](./TROUBLESHOOTING.zh.md). Kit overview: [README.md](../README.md).

**Verified with:** dsh `0.1.5-rc.1`, Daily plugins including [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) ≥0.1.1. Cloud Flash model id: **`deepseek-flash`** (V4.1 Flash).

## Quick map

| Symptom | Tool first | Plugin |
|---------|------------|--------|
| DeepSeek Search / `TypeError: fetch failed` | `net_doctor` (confirm **dsh process** `NODE_USE_ENV_PROXY=1` + proxy OPEN) → `check-dsh-health.sh` / `restart-dsh-web.sh` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| `web_fetch` still fails (API works; plugin installed) | Confirm Clash proxy; upgrade fetch ≥0.1.1 (retries + www↔apex); **new session**; try another URL | [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) |
| Red fetch UI but log shows `web_fetch via proxy` | Per-URL proxy/TLS/site failure — not “plugin missing” | dsh-wsl-fetch |
| Cloudflare / Workers **403 error 1010** via Clash | Add Clash **DIRECT** for that host (WAF), or use a path that works from Windows | — |
| Local LLM unreachable / ctx / HTTP 404 on /v1/models | `host_reach` (`apiReady` / `ctxReports`) → optional `docker_doctor` | [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) |
| settings `contextWindow` > Ollama `num_ctx` | `host_reach` → lower settings or raise `OLLAMA_NUM_CTX` | dsh-wsl-hostsvc |
| DeepSeek API / npm timeout | `net_doctor`; ensure `NO_PROXY` is loopback-only (see `restart-dsh-web.sh`) | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| ModelScope / Hugging Face | `net_doctor` target=`registry` | dsh-wsl-net |
| git push / GitHub 401 | `github_app_hint` + `cred_doctor` | github + cred |
| DNS weirdness | `dns_doctor` | [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) |
| WSL vs Windows A-record mismatch for same host | `dns_doctor` (then `net_doctor` / `wslconfig_hint`) | dsh-wsl-dns |
| TLS clock skew / post-sleep skew / GitHub App JWT oddities | `clock_doctor` (then `wsl --shutdown` if needed) | [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) |
| Workspace on Desktop/Downloads (`/mnt/c/...`) | `wsl_workspace` + `mnt_doctor` | [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) |
| Browser cannot open WSL dsh web | `check-dsh-health` → `port_doctor` → `restart-dsh-web` → (LAN only) `wsl_expose`; see §0 | [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) / expose |
| “Deep diving” forever on a trivial question | New session **without** Agent Teams; Teams is experimental and tool-heavy | upstream Agent Teams |
| Wrong / retired model id | Use **`deepseek-flash`** for V4.1 Flash; old `deepseek-v4-flash` only aliases temporarily | `~/.dsh/settings.yaml` |
| `CONTEXT_WINDOW_EXCEEDED` | Align settings `contextWindow` with Ollama `num_ctx` (≥32768 when many plugins) | hostsvc + settings |
| Tools behave like an old build / plugin missing | `bash scripts/check-plugin-versions.sh` → `dsh plugin add` + `restart-dsh-web.sh` | [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit) |

## 0. Windows browser ↔ WSL dsh (required)

dsh **must not** bind `--host 0.0.0.0`; it listens on `127.0.0.1:3080` only. Use the relay on Windows:

```text
ERR_CONNECTION_REFUSED / blank page
  → bash scripts/check-dsh-health.sh
  → port_doctor on 3080/3081 (uiPlaybook)
  → bash scripts/restart-dsh-web.sh
  → Open the printed ui= URL (dsh ≥0.1.2 needs ?token=; bare :3081 is 401)
  → not :3000; not bare :3080 unless mirrored verified
  → wsl_expose only for LAN / non-local UI — no netsh portproxy for local dsh UI

HTTP 401 Unauthorized
  → Expected on dsh 0.1.2+: one-shot launch token. Use restart output or /tmp/dsh-ui-url

ERR_CONNECTION_RESET (relay up, dsh down)
  → Same: health → port_doctor → restart; confirm both 3080 and 3081 are listening

/api 403 (Host rewrite broke Origin)
  → Do not rewrite Host; keep Host: 127.0.0.1:3081 + --trusted-host
```

## 1. Local LLM (Ollama / LM Studio / vLLM / Unsloth)

```text
host_reach (profile=all)
  ├─ all closed → service not up on Windows / bound 127.0.0.1 only under NAT
  │     → OLLAMA_HOST=0.0.0.0:11434 or LM Studio “local network”
  │     → or .wslconfig networkingMode=mirrored
  ├─ only Windows host IP works → set settings.yaml baseURL to suggestedBaseURL
  ├─ providerSnippets → paste into ~/.dsh/settings.yaml
  └─ ctx 400 / CONTEXT_WINDOW_EXCEEDED
        → settings contextWindow must be ≤ real Ollama n_ctx; raise both to ≥32768 when possible
```

**Install:** `KIT_SET=llm` (see [install.sh](../install.sh)).

## 2. HTTPS / proxy / npm

```text
net_doctor (target=all)
  ├─ HTTP_PROXY set but NODE_USE_ENV_PROXY ≠ 1
  │     → export NODE_USE_ENV_PROXY=1 then restart dsh web
  ├─ no proxy and probe FAIL
  │     → Windows Clash/V2Ray mixed port → http://127.0.0.1:7890 (or your port)
  ├─ npm OK but deepseek FAIL → proxy rules must allow api.deepseek.com
  └─ inherited Clash NO_PROXY=10.*,172.16.* …
        → Node skips proxy for “private” matches incorrectly; use restart-dsh-web.sh loopback-only NO_PROXY
```

Node 24 `fetch` **ignores** proxies by default. `dsh-wsl-net` injects `NODE_USE_ENV_PROXY=1` into **child** bash/npm; the **dsh main process** still needs that env (use `restart-dsh-web.sh`).

`web_fetch` is separate: install **dsh-wsl-fetch** so in-process fetch uses `ProxyAgent`.

## 3. GitHub / git push

1. `KIT_SET=github` installs github + cred
2. Configure App per [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github)
3. `source ~/.dsh/dsh-wsl-github.env` then start `dsh web`
4. Still failing → `cred_doctor`; **never** paste PEM/PAT into chat

## 4. Connectivity playbook (order)

1. **host_reach** — local inference ports  
2. **net_doctor** — outbound HTTPS + registry  
3. **dns_doctor** — resolve / WSL↔Windows A-record mismatch  
4. **clock_doctor** — clock skew (TLS / App JWT)  
5. **wsl_workspace** — workspace on Desktop / `/mnt`  
6. **wsl_expose** — only when Windows browser cannot reach WSL web (LAN)

`host_reach` returns a `connectivityPlaybook` field aligned with the above.

## 5. One-shot kit sets

| KIT_SET | Use |
|---------|-----|
| `daily` | Everyday WSL + browser (+ fetch) |
| `github` | daily + GitHub App |
| `llm` | Local models + network doctors + tray/expose (+ fetch) |
| `full` | All plugins in install.sh |

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=llm bash
```

After install: **restart dsh web** and open a **new session**.
