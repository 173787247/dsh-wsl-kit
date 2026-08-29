# dsh-wsl-kit

**One-click install pack** for DeepSeek Harness on **Windows + WSL**: browser on Windows, agent in WSL.

This meta-repo does not ship plugin code. It documents the suite and provides a ready `cordis.patch.yml` so you can enable the whole kit after installing each plugin once.

## What’s in the kit

| Plugin | Role |
|--------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | Inject WSL/Windows path & shell facts into the system prompt |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` — proxy / Node 24 fetch / DeepSeek+npm probes (+ copy-paste fix snippets) |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | Click Linux paths in chat → open in Windows |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | Hard-stop consecutive identical tool calls |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | Cap total tool calls per session (optional safety twin) |

Related (not required for day-1 kit): [session-contract](https://github.com/173787247/session-contract).

## Install (one-shot)

Already running `dsh web`:

```sh
dsh plugin --profile web add github:173787247/dsh-wsl-env
dsh plugin --profile web add github:173787247/dsh-wsl-net
dsh plugin --profile web add github:173787247/dsh-wsl-open
dsh plugin --profile web add github:173787247/dsh-repeat-stop
dsh plugin --profile web add github:173787247/dsh-tool-budget
```

Or local checkouts:

```sh
KIT=/absolute/path/to/AIFullStackDevelopment
dsh plugin --profile web add "$KIT/dsh-wsl-env"
dsh plugin --profile web add "$KIT/dsh-wsl-net"
dsh plugin --profile web add "$KIT/dsh-wsl-open"
dsh plugin --profile web add "$KIT/dsh-repeat-stop"
dsh plugin --profile web add "$KIT/dsh-tool-budget"
```

Restart `dsh web`. Open a **new** session.

### Optional: merge the kit patch

If you maintain a profile `cordis.patch.yml`, append the blocks from [`cordis.patch.yml`](./cordis.patch.yml) in this repo (or replace your rows for these plugin ids). Later layers that redefine a plugin `config` replace the whole object — restate every key you still want.

## Verify

1. **env** — Trajectory → SYSTEM → System Prompt → search `Windows Subsystem for Linux`.
2. **net** — Tools lists `net_doctor`; ask to check DeepSeek/npm; read `fix` / `advice`.
3. **open** — Agent writes a file under `/home/...`; path is clickable in chat.
4. **repeat-stop** — identical tool spam eventually errors with `dsh-repeat-stop: blocked`.
5. **tool-budget** — after the configured max calls, further tools are denied with `dsh-tool-budget: blocked`.

## Recommended dsh start (Node 24 + proxy)

If Clash/V2Ray runs on Windows and WSL needs the proxy:

```sh
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

`net_doctor` will print a ready-to-copy block when this is missing.

## Topics

On GitHub: `dsh-plugin`, `wsl`.

## License

MIT — same as the individual plugins.
