# dsh-wsl-kit

**One line:** DeepSeek Harness agent in WSL, chat in a Windows browser — install this kit when paths, proxy, clipboard, and “open that file” must cross the OS boundary.

This is a **meta-repo** (docs + install script + [`cordis.patch.yml`](./cordis.patch.yml)). It does not ship plugin runtimes. Each plugin repo ships English `README.md` and Chinese `README.zh.md`.

[中文说明 → README.zh.md](./README.zh.md)

---

## Compatibility (2026-09)

| Piece | Status |
|-------|--------|
| **dsh** | Verified with **`0.1.5-rc.1`** (npm `latest` as of 2026-09-10; no non-rc `0.1.5` yet). Kit scripts assume dsh **≥0.1.2** UI launch tokens (`?token=` on `:3081`). |
| **DeepSeek V4.1 Flash** | Official API model id is **`deepseek-flash`**. Legacy `deepseek-v4-flash` / `deepseek-v4-flash-vision-exp` temporarily route to V4.1 Flash. **Not configured by this kit** — set under `llm-deepseek` / default model in `~/.dsh/settings.yaml`. |
| **Agent Teams** | Opt-in experimental package (`@deepseek-ai/dsh-experimental-agent-team-profile`, same line as your dsh). **Not** part of `install.sh`. Expect longer “Deep diving” turns; use a fresh non-Teams session to smoke-test models. |
| **Plugins** | Floor versions: [`scripts/check-plugin-versions.sh`](./scripts/check-plugin-versions.sh). Daily includes [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) **≥0.1.1**. |

### Plugin README policy

- **This Compatibility section is the suite matrix.** Each plugin README has a matching **Compatibility** table (EN + ZH): minimum dsh **≥0.1.2**, pointer here for **latest verified**, kit set, and notes that cloud Flash / Agent Teams are not owned by WSL plugins.
- When dsh ships a new line (e.g. `0.1.5` GA or `0.1.6`), **update this kit table first**, then refresh plugin “currently …” lines (or re-run the suite doc sync). Do not invent per-plugin “verified” dates without a smoke pass.
- API-sensitive plugins (`net`, `fetch`, `port`, `expose`, `tray`, `hostsvc`) carry an extra **Scope** paragraph; thinner Daily tools keep the shared table only.

No kit code change is required solely for V4.1 Flash — update model ids in settings if you still default to retired names.

---

## 60-second start (recommended: Daily set)

**Prereq:** `dsh` works inside WSL (profile usually `web`). Prefer `0.1.5-rc.1` or newer from the same release train.

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=daily bash
```

Then:

1. Restart via [`scripts/restart-dsh-web.sh`](./scripts/restart-dsh-web.sh) (starts dsh on `:3080` **and** the Windows relay on `:3081`)
2. In Windows open the **URL printed by `restart-dsh-web.sh`** (dsh ≥0.1.2 includes `?token=`; bare `:3081` is 401. Not `:3080`). Token is also written to `/tmp/dsh-ui-url` (WSL).
3. Open a **new** session (old sessions keep the old toolset)
4. Optionally merge [`cordis.patch.yml`](./cordis.patch.yml) into your profile (a later plugin `config` **replaces** the whole object — restate every key you still need)

| Want | Command |
|------|---------|
| **Daily (recommended)** | `KIT_SET=daily bash install.sh` |
| Daily + GitHub App / credentials | `KIT_SET=github bash install.sh` |
| **Local LLM + network doctor** | `KIT_SET=llm bash install.sh` |
| Everything | `KIT_SET=full bash install.sh` (or omit `KIT_SET` — same as before) |

From a local clone: `KIT_SET=daily bash install.sh`

### What `restart-dsh-web.sh` loads

- `NODE_USE_ENV_PROXY=1`, `OLLAMA_API_KEY` default `ollama`
- `NO_PROXY=127.0.0.1,localhost` only (do **not** inherit Clash RFC1918 `NO_PROXY` globs — they make Node skip the proxy and timeout on `api.deepseek.com`)
- Optional: `source "$HOME/.dsh/dsh-wsl-github.env"` yourself before start when using GitHub App plugins

---

## What you get immediately

| Pain | Tool | Plugin |
|------|------|--------|
| Proxy / Node 24 blocks DeepSeek or npm | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| `web_fetch` `TypeError: fetch failed` (API works) | Install [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) ≥0.1.1 + `restart-dsh-web.sh` | [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) |
| Open a Linux path from chat on Windows | (clickable paths) | [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) |
| Path convert / slow `/mnt/c` | `path_convert` | [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) |
| Windows clipboard | `wsl_clipboard` | [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) |
| Open a PR / docs URL in Windows | `win_open_url` | [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) |
| Agent forgets it is in WSL | (system prompt inject) | [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) |

**Daily** = table above + `win_launch` + `dsh-repeat-stop` + `dsh-tool-budget` + **`dsh-wsl-fetch`**.

Smoke: in a new session ask “run `net_doctor`” and “copy this path to the Windows clipboard”. Prefer model **`deepseek-flash`** for cloud; keep Agent Teams off for first smoke.

---

## Install sets (short list)

| Set | Includes | Who |
|-----|----------|-----|
| **Daily** | env, net, **fetch**, open, repeat-stop, tool-budget, clipboard, path, browser, launch | Most WSL + Windows-browser users |
| **GitHub day** | Daily + [github](https://github.com/173787247/dsh-wsl-github) + [cred](https://github.com/173787247/dsh-wsl-cred) + notify | Also need PR/Actions status and `git push` credential hints |
| **LLM** | env, net, **fetch**, hostsvc, docker, dns, clock, gpu, port, expose, tray, open, path, browser | Local Ollama / vLLM / Unsloth + connectivity |
| **Full** | Everything in [`install.sh`](./install.sh) | GPU/Docker/clock doctors, tray, portproxy, etc. |

**Do not** start with Full — get Daily working, then add plugins for specific pains.

### Optional: GitHub day

GitHub from WSL is credentials + API + browser open + proxy — not one mega-plugin. After `KIT_SET=github`:

1. Create the App per [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github#readme) (read-only Metadata / PRs / Actions; webhooks off)
2. Before start: `source "$HOME/.dsh/dsh-wsl-github.env"`
3. New session → `github_app_hint` / `github_repo_status`; **never** paste PEM / PAT into chat

---

## Node 24 + Windows proxy

```sh
export HTTP_PROXY=http://127.0.0.1:7890   # or Clash mixed port, e.g. 16006
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
# Prefer restart-dsh-web.sh so NO_PROXY stays loopback-only
```

Still failing → ask the agent to run `net_doctor`.

- **API works, `web_fetch` fails** → [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) (Daily already installs it).
- **Third-party Workers / Cloudflare 403 (1010) via Clash** → add a **DIRECT** rule for that host (plugin cannot override site WAF).

Local OpenAI-compatible backends on Windows: add [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc), run `host_reach`, merge [`examples/local-llm-providers.settings.yaml`](./examples/local-llm-providers.settings.yaml).

---

## Troubleshooting

Connectivity, UI token 401, Ollama ctx, and fetch faults: **[docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)** (中文: [TROUBLESHOOTING.zh.md](./docs/TROUBLESHOOTING.zh.md)).

Order of play: `host_reach` → `net_doctor` → `dns_doctor` → `clock_doctor` → workspace/mnt → expose (LAN only).

---

## Full catalog (reference)

<details>
<summary>Expand all plugins</summary>

### Daily (`KIT_SET=daily`)

| Plugin | Role |
|--------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | Inject WSL/Windows facts into the system prompt |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` |
| [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) | Proxy-aware `web_fetch` (undici `ProxyAgent`) |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | Open Linux paths from chat on Windows |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | Hard-stop identical tool loops |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | Cap tool calls per session |
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard` |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert` |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch` (allowlisted) |

### GitHub add-ons

| Plugin | Role |
|--------|------|
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_app_hint` / `github_repo_status` |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint` (no secrets) |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify` |

### Doctors / UI / tier 2

| Plugin | Role |
|--------|------|
| [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) | `gpu_doctor` |
| [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) | `port_doctor` |
| [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) | `distro_info` |
| [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) | `wsl_workspace` |
| [dsh-wsl-picker](https://github.com/173787247/dsh-wsl-picker) | `wsl_picker` |
| [dsh-wsl-tray](https://github.com/173787247/dsh-wsl-tray) | `wsl_tray` |
| [dsh-wsl-expose](https://github.com/173787247/dsh-wsl-expose) | `wsl_expose` |
| [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) | `host_reach` |
| [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) | `clock_doctor` |
| [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) | `dns_doctor` |
| [dsh-wsl-mnt](https://github.com/173787247/dsh-wsl-mnt) | `mnt_doctor` |
| [dsh-wsl-editor](https://github.com/173787247/dsh-wsl-editor) | `win_editor` |
| [dsh-wsl-shot](https://github.com/173787247/dsh-wsl-shot) | `win_shot` |
| [dsh-wsl-docker](https://github.com/173787247/dsh-wsl-docker) | `docker_doctor` |
| [dsh-wsl-ssh-agent](https://github.com/173787247/dsh-wsl-ssh-agent) | `ssh_agent_hint` |
| [dsh-wsl-encoding](https://github.com/173787247/dsh-wsl-encoding) | `encoding_doctor` |
| [dsh-wsl-wslconfig](https://github.com/173787247/dsh-wsl-wslconfig) | `wslconfig_hint` |
| [dsh-wsl-download](https://github.com/173787247/dsh-wsl-download) | `win_download` |

Related: [session-contract](https://github.com/173787247/session-contract). Awesome listing snippet: [`awesome-wsl-kit.md`](./awesome-wsl-kit.md). Fetch awesome PR: [awesome-dsh-plugin#4736](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/4736).

</details>

---

## Beyond the kit (growth)

| Track | Notes | Status |
|-------|-------|--------|
| dsh 0.1.5-rc.1 + `deepseek-flash` | Docs / settings; kit install path unchanged | Documented this round |
| `dsh-wsl-fetch` ≥0.1.1 in Daily/LLM | Retries, shared ProxyAgent, www↔apex | Done; awesome PR open |
| Install drift | [`check-plugin-versions.sh`](./scripts/check-plugin-versions.sh) | Done |
| Startup health | `check-dsh-health` accepts 401 + tray token URL | Done |
| Local LLM probes | `hostsvc` `apiReady` + `docker` HTTP 404 | Done |
| Browser / UI relay | `port` / `expose` + dsh ≥0.1.2 auth | Done |
| Thin UX plugins | editor / shot / notify / picker deepen | Deferred |
| Agent Teams | Upstream experimental; not kit | Out of scope |
| MCP / DingTalk / OpenClaw | Separate product lines | Do not force into WSL plugins |

## Security

- Plugins share your Harness permissions (files, network, Windows via PowerShell/`cmd`).
- `win_launch` is allowlisted; `cred_hint` / GitHub App never dump secrets into chat.
- `win_notify` blocks on a MessageBox — keep text short and secret-free.
- Keep `*.env` under `~/.dsh/` at `chmod 600`; never commit API keys.

## Topics

`deepseek-harness` · `dsh-plugin` · `wsl` · `windows` · `github-app`

## License

MIT — same as the individual plugins.
