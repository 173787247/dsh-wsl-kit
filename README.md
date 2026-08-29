# dsh-wsl-kit

**One-click install pack** for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) on **Windows + WSL**: browser on Windows, agent in WSL.

This meta-repo does **not** ship plugin runtime code. It documents the suite, lists install order, and provides a ready [`cordis.patch.yml`](./cordis.patch.yml) you can merge into your profile after installing the plugins.

[中文说明 ↓](#中文)

---

## English

### Who this is for

You run `dsh web` inside WSL (Ubuntu, etc.) while Chat / Trajectory opens in a Windows browser. Paths, proxy, clipboard, and “open this file” all cross the OS boundary—this kit is the glue.

### What’s included

#### Core (day-1)

| Plugin | Role |
|--------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | Inject WSL/Windows path & shell facts into the system prompt |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` — proxy / Node 24 fetch / DeepSeek + npm probes (+ fix snippets) |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | Click Linux paths in chat → open in Windows |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | Hard-stop consecutive identical tool calls |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | Cap total tool calls per session |

#### Bridge & ergonomics

| Plugin | Role |
|--------|------|
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard` — read/write the Windows clipboard |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch` — start allowlisted Windows apps |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert` — Linux ↔ Windows paths + `/mnt/c` caveats |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` — open `http(s)` in the Windows browser |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify` — Windows MessageBox when a long task finishes |
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_repo_status` — GitHub App: open PRs + latest Actions (no secrets) |

#### Diagnostics (install when needed)

| Plugin | Role |
|--------|------|
| [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) | `gpu_doctor` — `nvidia-smi` / CUDA visibility in WSL |
| [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) | `port_doctor` — listen + localhost forwarding hints |
| [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) | `distro_info` — multi-distro / `os-release` facts |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint` — Git Credential Manager guidance (**never** dumps secrets) |

Optional related: [session-contract](https://github.com/173787247/session-contract).

### Recommended install sets

| Set | Plugins |
|-----|---------|
| **Minimal** | env, net, open, repeat-stop |
| **Daily** | Minimal + tool-budget, clipboard, path, browser, launch |
| **Full** | Everything in [`install.sh`](./install.sh) |

### Install

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
         dsh-wsl-clipboard dsh-wsl-launch dsh-wsl-path dsh-wsl-browser dsh-wsl-github; do
  dsh plugin --profile web add "$KIT/$p"
done
```

Then:

1. Restart `dsh web`.
2. Open a **new** session (old sessions keep the old prompt/tools).
3. Optionally merge [`cordis.patch.yml`](./cordis.patch.yml) into your profile patch.  
   **Important:** a later layer that sets a plugin `config` replaces the **entire** object—restate every key you still want.

### Suggested `dsh` start (Node 24 + Windows proxy)

If Clash / V2Ray runs on Windows and WSL must use it:

```sh
export HTTP_PROXY=http://127.0.0.1:7890   # change port to yours
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

Ask the agent to run `net_doctor` if API / npm still fails.

### Verify (smoke)

| Check | How |
|-------|-----|
| env | Trajectory → SYSTEM → System Prompt → search `Windows Subsystem for Linux` |
| net | Tools lists `net_doctor`; ask to probe DeepSeek / npm |
| open | Agent writes under `/home/...`; path is clickable |
| clipboard | Ask to copy a path to the Windows clipboard |
| path | Ask to convert `/mnt/c/Users/...` ↔ `C:\Users\...` |
| repeat-stop / budget | Spam identical tools → `dsh-*-*: blocked` in Trajectory |
| github | Tools lists `github_app_hint` / `github_repo_status`; ask after App env is set |

### Security notes

- Plugins run with your Harness permissions (files, network, Windows interop via PowerShell/`cmd`).
- `win_launch` is **allowlisted**; extend `config.allowlist` deliberately.
- `cred_hint` only prints helper configuration advice—never tokens.
- `github_repo_status` uses a GitHub App installation token in memory; never paste the PEM into chat.
- `win_notify` uses a blocking MessageBox; keep titles/bodies short and secret-free.

### Topics

`deepseek-harness` · `dsh-plugin` · `wsl`

### License

MIT — same as the individual plugins.

---

## 中文

### 适用场景

在 **WSL** 里跑 `dsh web`，用 **Windows 浏览器** 打开聊天界面。路径、代理、剪贴板、「打开这个文件」都要跨系统——本套件就是把这些胶水插件装齐、配齐。

本仓库是**元仓**：不包含插件运行时代码，只提供文档、安装顺序和可合并的 [`cordis.patch.yml`](./cordis.patch.yml)。

### 包含内容

#### 核心（建议第一天就装）

| 插件 | 作用 |
|------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | 向 system prompt 注入 WSL/Windows 路径与 shell 事实 |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor`：代理 / Node 24 fetch / DeepSeek+npm 探测（含可复制修复脚本） |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | 聊天里的 Linux 路径一键在 Windows 打开 |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | 连续相同工具调用硬拦截 |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | 会话级工具调用次数上限 |

#### 互通与效率

| 插件 | 作用 |
|------|------|
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard`：读写 Windows 剪贴板 |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch`：白名单启动 Windows 应用 |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert`：路径互转 + `/mnt/c` 注意点 |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url`：在 Windows 默认浏览器打开链接 |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify`：长任务结束后弹出 Windows 提示框 |
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_repo_status`：GitHub App 查未关闭 PR 与最近一次 Actions（不回传密钥） |

#### 诊断（按需）

| 插件 | 作用 |
|------|------|
| [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) | `gpu_doctor`：WSL 内 GPU / `nvidia-smi` |
| [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) | `port_doctor`：端口监听与 localhost 转发 |
| [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) | `distro_info`：多发行版提醒 |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint`：Git 凭据管理指引（**不**输出密钥） |

### 推荐安装组合

| 组合 | 内容 |
|------|------|
| **最小** | env、net、open、repeat-stop |
| **日常** | 最小 + tool-budget、clipboard、path、browser、launch |
| **完整** | [`install.sh`](./install.sh) 里全部 |

### 安装

**前提：** 已安装 DeepSeek Harness；WSL 里 `dsh` 可用；配置文件一般是 `web`。

一键（从 GitHub 拉插件）：

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh | bash
# 或克隆本仓后：
bash install.sh
```

然后重启 `dsh web`，并开一个**新会话**。可选：把 [`cordis.patch.yml`](./cordis.patch.yml) 合并进你的 profile。注意：后写的插件 `config` 会**整段替换**，需要的键都要重新写全。

### 建议的启动方式（Node 24 + Windows 代理）

```sh
export HTTP_PROXY=http://127.0.0.1:7890   # 改成你的端口
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

API / npm 仍不通时，让 Agent 跑 `net_doctor`。

### 安全提示

- 插件与 Harness 同权（读文件、联网、经 PowerShell 调 Windows）。
- `win_launch` 有白名单，扩 `allowlist` 时请谨慎。
- `cred_hint` 只给配置建议，不回传 token。
- `github_repo_status` 只在内存里换 GitHub App token，私钥不要贴进对话。
- `win_notify` 会阻塞弹出 MessageBox，文案勿含密钥。

### 许可

MIT（与各子插件相同）。
