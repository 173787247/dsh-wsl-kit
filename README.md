# dsh-wsl-kit

**One-click install pack** for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) on **Windows + WSL**: browser on Windows, agent in WSL.

This meta-repo does **not** ship plugin runtime code. It documents the suite, lists install order, and provides a ready [`cordis.patch.yml`](./cordis.patch.yml) you can merge into your profile after installing the plugins.

Every plugin in this suite ships the same doc split: **English** `README.md` + **Chinese** `README.zh.md`, with mutual links at the top.

[中文说明 → README.zh.md](./README.zh.md)

---

## Who this is for

You run `dsh web` inside WSL (Ubuntu, etc.) while Chat / Trajectory opens in a Windows browser. Paths, proxy, clipboard, and “open this file” all cross the OS boundary—this kit is the glue.

## Why this kit for GitHub

When DSH lives in **WSL** and you need **GitHub**, “connect to GitHub” is not one problem. Push credentials, REST API calls, opening links in Windows, and proxy failures are different jobs. The kit keeps them as **small plugins** that work together—instead of pasting a PAT into chat or installing a 40-tool generic GitHub connector.

| Job | Plugin | Tool |
|-----|--------|------|
| `git push` / HTTPS credentials (Windows GCM from WSL) | [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint` |
| GitHub API: open PRs + latest Actions | [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_app_hint`, `github_repo_status` |
| Open a PR / Actions URL in the Windows browser | [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` |
| Proxy / Node 24 fetch blocks `api.github.com` or DeepSeek | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` |

**Advantages**

- **Boundary-aware** — Agent in WSL, UI in Windows; credentials and browser stay on the right side of the OS line.
- **GitHub App, not chat secrets** — `dsh-wsl-github` mints a short-lived installation token in memory. Never paste a PEM or PAT into the prompt.
- **Least privilege** — App asks only for Metadata / Pull requests / Actions **read**. Webhooks off.
- **Composable** — Same install pack as path, clipboard, and notify tools; one `install.sh` / `cordis.patch.yml`.
- **Developer Program ready** — A real GitHub App + API integration owned by you (homepage can be this kit repo).

Full App setup and env loading: [dsh-wsl-github README](https://github.com/173787247/dsh-wsl-github#readme).

### Typical GitHub workflow (WSL agent)

1. Install the **Full** set (or **Daily** + `dsh-wsl-github` + `dsh-wsl-cred`).
2. Create / install the GitHub App once (`npm run register-app` in `dsh-wsl-github`, or follow that repo’s docs).
3. Before `dsh web`, load App env (WSL):

```sh
set -a
source "$HOME/.dsh/dsh-wsl-github.env"
set +a
# optional proxy (Clash / V2Ray on Windows):
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

4. Open a **new** session. Ask the agent, for example:
   - “Run `github_app_hint` — are we authenticated?”
   - “Run `github_repo_status` for this repo.”
   - “Open that PR URL with `win_open_url`.”
   - If API fails: “Run `net_doctor`.”
   - If `git push` fails: “Run `cred_hint`.”

Do **not** paste `GITHUB_APP_*` values or the PEM into chat.

## What’s included

### Core (day-1)

| Plugin | Role |
|--------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | Inject WSL/Windows path & shell facts into the system prompt |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` — proxy / Node 24 fetch / DeepSeek + npm probes (+ fix snippets) |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | Click Linux paths in chat → open in Windows |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | Hard-stop consecutive identical tool calls |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | Cap total tool calls per session |

### Bridge & ergonomics

| Plugin | Role |
|--------|------|
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard` — read/write the Windows clipboard |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch` — start allowlisted Windows apps |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert` — Linux ↔ Windows paths + `/mnt/c` caveats |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` — open `http(s)` in the Windows browser |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify` — Windows MessageBox when a long task finishes |
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_repo_status` — GitHub App: open PRs + latest Actions (no secrets) |

### Diagnostics (install when needed)

| Plugin | Role |
|--------|------|
| [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) | `gpu_doctor` — `nvidia-smi` / CUDA visibility in WSL |
| [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) | `port_doctor` — listen + localhost forwarding hints |
| [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) | `distro_info` — multi-distro / `os-release` facts |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint` — Git Credential Manager guidance (**never** dumps secrets) |

### WSL UI counterparts

| Plugin | Role |
|--------|------|
| [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) | `wsl_workspace` — list distros + validate a Linux workspace path |
| [dsh-wsl-picker](https://github.com/173787247/dsh-wsl-picker) | `wsl_picker` — browse `/` and `/mnt` for workspace picking |
| [dsh-wsl-tray](https://github.com/173787247/dsh-wsl-tray) | `wsl_tray` — Windows tray/shortcut launcher for `dsh web` |
| [dsh-wsl-expose](https://github.com/173787247/dsh-wsl-expose) | `wsl_expose` — allowlisted Windows portproxy for a WSL port |

### Tier 1 bridge & doctors

| Plugin | Role |
|--------|------|
| [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) | `host_reach` — probe Ollama / LM Studio / vLLM / llama-server on Windows; suggest `baseURL` |
| [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) | `clock_doctor` — WSL2 clock drift after sleep (TLS / tokens) |
| [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) | `dns_doctor` — compare WSL vs Windows DNS |
| [dsh-wsl-mnt](https://github.com/173787247/dsh-wsl-mnt) | `mnt_doctor` — warn when workspace sits on slow `/mnt/c` |
| [dsh-wsl-editor](https://github.com/173787247/dsh-wsl-editor) | `win_editor` — open a Linux path in Cursor / VS Code / Notepad |
| [dsh-wsl-shot](https://github.com/173787247/dsh-wsl-shot) | `win_shot` — save Windows clipboard image into WSL |

### Tier 2 extras

| Plugin | Role |
|--------|------|
| [dsh-wsl-docker](https://github.com/173787247/dsh-wsl-docker) | `docker_doctor` — Docker Desktop vs WSL context confusion |
| [dsh-wsl-ssh-agent](https://github.com/173787247/dsh-wsl-ssh-agent) | `ssh_agent_hint` — forward Windows OpenSSH agent into WSL |
| [dsh-wsl-encoding](https://github.com/173787247/dsh-wsl-encoding) | `encoding_doctor` — UTF-8 vs Windows code-page issues |
| [dsh-wsl-wslconfig](https://github.com/173787247/dsh-wsl-wslconfig) | `wslconfig_hint` — read-only `.wslconfig` memory / mirrored networking advice |
| [dsh-wsl-download](https://github.com/173787247/dsh-wsl-download) | `win_download` — copy from Windows Downloads into the WSL workspace |

Optional related: [session-contract](https://github.com/173787247/session-contract).

## Recommended install sets

| Set | Plugins |
|-----|---------|
| **Minimal** | env, net, open, repeat-stop |
| **Daily** | Minimal + tool-budget, clipboard, path, browser, launch |
| **GitHub day** | Daily + [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) + [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) |
| **WSL UI** | Daily + workspace, picker, tray, expose |
| **Doctors** | WSL UI + hostsvc, clock, dns, mnt, editor, shot |
| **Full** | Everything in [`install.sh`](./install.sh) (includes Tier 2) |

Local OpenAI-compatible backends (Ollama / LM Studio / vLLM / llama-server): run `host_reach`, then merge [`examples/local-llm-providers.settings.yaml`](./examples/local-llm-providers.settings.yaml) into `~/.dsh/settings.yaml`.

## Install

**Prerequisites:** DeepSeek Harness installed; `dsh` on `PATH` inside WSL; profile usually `web`.

One-shot (GitHub sources):

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh | bash
# or clone this repo and:
bash install.sh
# optional: DSH_PROFILE=web bash install.sh
```

Local checkouts (example):

```sh
KIT=/absolute/path/to/AIFullStackDevelopment
for p in dsh-wsl-env dsh-wsl-net dsh-wsl-open dsh-repeat-stop dsh-tool-budget \
         dsh-wsl-clipboard dsh-wsl-launch dsh-wsl-path dsh-wsl-browser dsh-wsl-github \
         dsh-wsl-workspace dsh-wsl-picker dsh-wsl-tray dsh-wsl-expose \
         dsh-wsl-hostsvc dsh-wsl-clock dsh-wsl-dns dsh-wsl-mnt dsh-wsl-editor dsh-wsl-shot \
         dsh-wsl-docker dsh-wsl-ssh-agent dsh-wsl-encoding dsh-wsl-wslconfig dsh-wsl-download; do
  dsh plugin --profile web add "link:$KIT/$p"
done
```

Then:

1. Restart `dsh web`.
2. Open a **new** session (old sessions keep the old prompt/tools).
3. Optionally merge [`cordis.patch.yml`](./cordis.patch.yml) into your profile patch.  
   **Important:** a later layer that sets a plugin `config` replaces the **entire** object—restate every key you still want.

## Suggested `dsh` start (Node 24 + Windows proxy)

If Clash / V2Ray runs on Windows and WSL must use it:

```sh
export HTTP_PROXY=http://127.0.0.1:7890   # change port to yours
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

Ask the agent to run `net_doctor` if API / npm still fails.

## Verify (smoke)

| Check | How |
|-------|-----|
| env | Trajectory → SYSTEM → System Prompt → search `Windows Subsystem for Linux` |
| net | Tools lists `net_doctor`; ask to probe DeepSeek / npm |
| open | Agent writes under `/home/...`; path is clickable |
| clipboard | Ask to copy a path to the Windows clipboard |
| path | Ask to convert `/mnt/c/Users/...` ↔ `C:\Users\...` |
| repeat-stop / budget | Spam identical tools → `dsh-*-*: blocked` in Trajectory |
| github | Tools list `github_app_hint` / `github_repo_status`; after App env is loaded, ask for current-repo status |

## Security notes

- Plugins run with your Harness permissions (files, network, Windows interop via PowerShell/`cmd`).
- `win_launch` is **allowlisted**; extend `config.allowlist` deliberately.
- `cred_hint` only prints helper configuration advice—never tokens.
- `github_repo_status` uses a GitHub App installation token in memory; never paste the PEM into chat.
- `win_notify` uses a blocking MessageBox; keep titles/bodies short and secret-free.

## Topics

`deepseek-harness` · `dsh-plugin` · `wsl` · `github-app`

## License

MIT — same as the individual plugins.
