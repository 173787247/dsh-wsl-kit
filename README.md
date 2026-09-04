# dsh-wsl-kit

**One line:** DeepSeek Harness agent in WSL, chat in a Windows browser — install this kit when paths, proxy, clipboard, and “open that file” must cross the OS boundary.

This is a **meta-repo** (docs + install script + [`cordis.patch.yml`](./cordis.patch.yml)). It does not ship plugin runtimes. Each plugin repo ships English `README.md` and Chinese `README.zh.md`.

[中文说明 → README.zh.md](./README.zh.md)

---

## 60-second start (recommended: Daily set)

**Prereq:** `dsh` works inside WSL (profile usually `web`).

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=daily bash
```

Then:

1. Restart via [`scripts/restart-dsh-web.sh`](./scripts/restart-dsh-web.sh) (starts dsh on `:3080` **and** the Windows relay on `:3081`)
2. In Windows open **http://127.0.0.1:3081/** (not `:3080` — dsh binds loopback inside WSL only)
3. Open a **new** session (old sessions keep the old toolset)
4. Optionally merge [`cordis.patch.yml`](./cordis.patch.yml) into your profile (a later plugin `config` **replaces** the whole object — restate every key you still need)

| Want | Command |
|------|---------|
| **Daily (recommended)** | `KIT_SET=daily bash install.sh` |
| Daily + GitHub App / credentials | `KIT_SET=github bash install.sh` |
| **Local LLM + network doctor** | `KIT_SET=llm bash install.sh` |
| Everything | `KIT_SET=full bash install.sh` (or omit `KIT_SET` — same as before) |

From a local clone: `KIT_SET=daily bash install.sh`

---

## What you get immediately

| Pain | Tool | Plugin |
|------|------|--------|
| Proxy / Node 24 blocks DeepSeek or npm | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| Open a Linux path from chat on Windows | (clickable paths) | [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) |
| Path convert / slow `/mnt/c` | `path_convert` | [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) |
| Windows clipboard | `wsl_clipboard` | [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) |
| Open a PR / docs URL in Windows | `win_open_url` | [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) |
| Agent forgets it is in WSL | (system prompt inject) | [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) |

**Daily** = table above + `win_launch` + `dsh-repeat-stop` + `dsh-tool-budget` (9 plugins).

Smoke: in a new session ask “run `net_doctor`” and “copy this path to the Windows clipboard”.

---

## Install sets (short list)

| Set | Includes | Who |
|-----|----------|-----|
| **Daily** | env, net, open, repeat-stop, tool-budget, clipboard, path, browser, launch | Most WSL + Windows-browser users |
| **GitHub day** | Daily + [github](https://github.com/173787247/dsh-wsl-github) + [cred](https://github.com/173787247/dsh-wsl-cred) | Also need PR/Actions status and `git push` credential hints |
| **LLM** | env, net, hostsvc, docker, dns, clock, gpu, port, expose, tray, open, path, browser | Local Ollama / vLLM / Unsloth + connectivity |
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
export HTTP_PROXY=http://127.0.0.1:7890   # your port
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

Still failing → ask the agent to run `net_doctor`.

Local OpenAI-compatible backends on Windows: add [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc), run `host_reach`, merge [`examples/local-llm-providers.settings.yaml`](./examples/local-llm-providers.settings.yaml).

---

## Full catalog (reference)

<details>
<summary>Expand all plugins</summary>

### Daily (`KIT_SET=daily`)

| Plugin | Role |
|--------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | Inject WSL/Windows facts into the system prompt |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` |
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

Related: [session-contract](https://github.com/173787247/session-contract).

</details>

---

## Beyond the kit (growth)

| Track | Notes | Status |
|-------|-------|--------|
| Install drift | [`check-plugin-versions.sh`](./scripts/check-plugin-versions.sh); install mnt/encoding/ssh-agent | Done this round |
| Startup health | `net` 0.5.1 process env + [`check-dsh-health.sh`](./scripts/check-dsh-health.sh) + tray 0.2.2 | Done this round |
| Local LLM probes | `hostsvc` 0.4.2 `apiReady` + `docker` 0.2.2 HTTP 404 | Done this round |
| Browser / UI relay | `port` 0.2.1 `uiPlaybook` + `expose` 0.2.1 + health fault tree | Done this round |
| path/cred floor | Install to sibling 0.2; version-check floors | Done this round |
| Prior verticals | dns/clock/workspace/distro/github → 0.2 | Done previously |
| Thin UX plugins | `browser` / `clipboard` / `launch` / `editor` / `shot` / `notify` / `picker` | Deferred |
| MCP / DingTalk / OpenClaw | Separate product lines | Do not force into WSL plugins |

## Security

- Plugins share your Harness permissions (files, network, Windows via PowerShell/`cmd`).
- `win_launch` is allowlisted; `cred_hint` / GitHub App never dump secrets into chat.
- `win_notify` blocks on a MessageBox — keep text short and secret-free.

## Topics

`deepseek-harness` · `dsh-plugin` · `wsl` · `windows` · `github-app`

## License

MIT — same as the individual plugins.
