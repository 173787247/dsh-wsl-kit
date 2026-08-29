# dsh-wsl-kit

**One-click install pack** for DeepSeek Harness on **Windows + WSL**: browser on Windows, agent in WSL.

This meta-repo does not ship plugin code. It documents the suite and provides a ready `cordis.patch.yml` so you can enable the whole kit after installing each plugin once.

## What’s in the kit

### Core (day-1)

| Plugin | Role |
|--------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | Inject WSL/Windows path & shell facts into the system prompt |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` — proxy / Node 24 fetch / DeepSeek+npm probes (+ fix snippets) |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | Click Linux paths in chat → open in Windows |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | Hard-stop consecutive identical tool calls |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | Cap total tool calls per session |

### Bridge & ergonomics

| Plugin | Role |
|--------|------|
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard` — Windows clipboard get/set |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch` — allowlisted Windows apps |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert` — Linux ↔ Windows paths + `/mnt/c` caveats |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` — open http(s) in Windows browser |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify` — Windows MessageBox when a long task finishes |

### Diagnostics

| Plugin | Role |
|--------|------|
| [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) | `gpu_doctor` — nvidia-smi / CUDA visibility |
| [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) | `port_doctor` — listen + localhost forwarding hints |
| [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) | `distro_info` — multi-distro / os-release facts |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint` — Git Credential Manager guidance (no secrets) |

Related (optional): [session-contract](https://github.com/173787247/session-contract).

## Install (one-shot)

```sh
bash install.sh
# or set DSH_PROFILE=web explicitly
```

Or add individually — see `install.sh` for the full ordered list.

Restart `dsh web`. Open a **new** session.

### Optional: merge the kit patch

Append blocks from [`cordis.patch.yml`](./cordis.patch.yml) into your profile. Later layers that redefine a plugin `config` replace the whole object — restate every key you still want.

## Topics

On GitHub: `dsh-plugin`, `deepseek-harness`, `wsl`.

## License

MIT — same as the individual plugins.
