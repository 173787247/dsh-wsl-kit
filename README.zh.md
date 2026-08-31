# dsh-wsl-kit

面向 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 的 **Windows + WSL 一键套件**：Agent 在 WSL，聊天界面在 Windows 浏览器。

本仓库是**元仓**，不含插件运行时代码；提供文档、安装顺序，以及装完插件后可合并进 profile 的 [`cordis.patch.yml`](./cordis.patch.yml)。

套件内每个子插件仓库都同样拆成：**英文** `README.md` + **中文** `README.zh.md`，顶部互链。

[English → README.md](./README.md)

---

## 适用场景

在 **WSL**（Ubuntu 等）里跑 `dsh web`，用 **Windows 浏览器** 打开 Chat / Trajectory。路径、代理、剪贴板、「打开这个文件」都要跨系统——本套件就是把这些胶水插件装齐、配齐。

## 为什么连 GitHub 也走这套 kit

DSH 跑在 **WSL**、又要碰 **GitHub** 时，「连上 GitHub」其实是好几件事：推送凭据、调 REST API、在 Windows 打开链接、代理导致打不通。kit 把它们拆成**小插件**一起用——而不是把 PAT 贴进对话，或装一个 40 个工具的通用 GitHub 连接器。

| 要做的事 | 插件 | 工具 |
|----------|------|------|
| `git push` / HTTPS 凭据（WSL 接到 Windows GCM） | [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint` |
| GitHub API：未关闭 PR + 最近一次 Actions | [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_app_hint`、`github_repo_status` |
| 在 Windows 浏览器打开 PR / Actions 链接 | [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` |
| 代理 / Node 24 导致打不通 `api.github.com` 或 DeepSeek | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` |

**优势**

- **贴合跨界** — Agent 在 WSL、界面在 Windows；凭据与浏览器落在正确一侧。
- **用 GitHub App，不用聊天里的密钥** — `dsh-wsl-github` 只在内存里换短期 installation token，不要把 PEM / PAT 贴进 prompt。
- **最小权限** — App 只要 Metadata / Pull requests / Actions 的**读**权限，关掉 webhook。
- **可组合** — 与路径、剪贴板、通知同一套装；一次 `install.sh` / 一份 `cordis.patch.yml`。
- **能正经报名 Developer Program** — 你自己的 GitHub App + API 集成（Homepage 可用本 kit 仓库）。

App 创建与环境变量细节见：[dsh-wsl-github 中文说明](https://github.com/173787247/dsh-wsl-github/blob/master/README.zh.md)。

### 典型用法（WSL 里的 Agent）

1. 装 **完整** 套件（或 **日常** + `dsh-wsl-github` + `dsh-wsl-cred`）。
2. 一次性创建并安装 GitHub App（在 `dsh-wsl-github` 目录跑 `npm run register-app`，或按该仓文档操作）。
3. 启动 `dsh web` 前加载 App 环境（WSL）：

```sh
set -a
source "$HOME/.dsh/dsh-wsl-github.env"
set +a
# 若 Windows 上有 Clash / V2Ray，可按需：
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

4. 开一个**新会话**，例如对 Agent 说：
   - 「跑一下 `github_app_hint`，看鉴权好了没。」
   - 「对当前仓库跑 `github_repo_status`。」
   - 「用 `win_open_url` 打开那个 PR 链接。」
   - API 不通时：「跑 `net_doctor`。」
   - `git push` 失败时：「跑 `cred_hint`。」

**不要**把 `GITHUB_APP_*` 或 PEM 内容贴进聊天。

## 包含内容

### 核心（建议第一天就装）

| 插件 | 作用 |
|------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | 向 system prompt 注入 WSL/Windows 路径与 shell 事实 |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor`：代理 / Node 24 fetch / DeepSeek+npm 探测（含可复制修复脚本） |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | 聊天里的 Linux 路径一键在 Windows 打开 |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | 连续相同工具调用硬拦截 |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | 会话级工具调用次数上限 |

### 互通与效率

| 插件 | 作用 |
|------|------|
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard`：读写 Windows 剪贴板 |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch`：白名单启动 Windows 应用 |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert`：路径互转 + `/mnt/c` 注意点 |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url`：在 Windows 默认浏览器打开链接 |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify`：长任务结束后弹出 Windows 提示框 |
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_repo_status`：GitHub App 查未关闭 PR 与最近一次 Actions（不回传密钥） |

### 诊断（按需）

| 插件 | 作用 |
|------|------|
| [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) | `gpu_doctor`：WSL 内 GPU / `nvidia-smi` |
| [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) | `port_doctor`：端口监听与 localhost 转发 |
| [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) | `distro_info`：多发行版提醒 |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint`：Git 凭据管理指引（**不**输出密钥） |

### WSL UI 对应版

| 插件 | 作用 |
|------|------|
| [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) | `wsl_workspace`：列出发行版并校验 Linux 工作区路径 |
| [dsh-wsl-picker](https://github.com/173787247/dsh-wsl-picker) | `wsl_picker`：浏览 `/` 与 `/mnt` 选工作区 |
| [dsh-wsl-tray](https://github.com/173787247/dsh-wsl-tray) | `wsl_tray`：Windows 托盘/快捷方式启动 `dsh web` |
| [dsh-wsl-expose](https://github.com/173787247/dsh-wsl-expose) | `wsl_expose`：白名单 Windows portproxy 暴露 WSL 端口 |

### 一梯队互通与诊断

| 插件 | 作用 |
|------|------|
| [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) | `host_reach`：从 WSL 探测 Windows 主机服务（Ollama 等） |
| [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) | `clock_doctor`：休眠后 WSL2 时钟漂移（TLS / token） |
| [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) | `dns_doctor`：对比 WSL 与 Windows DNS |
| [dsh-wsl-mnt](https://github.com/173787247/dsh-wsl-mnt) | `mnt_doctor`：工作区落在缓慢 `/mnt/c` 时告警 |
| [dsh-wsl-editor](https://github.com/173787247/dsh-wsl-editor) | `win_editor`：用 Cursor / VS Code / Notepad 打开 Linux 路径 |
| [dsh-wsl-shot](https://github.com/173787247/dsh-wsl-shot) | `win_shot`：把 Windows 剪贴板图片存进 WSL |

### 二梯队扩展

| 插件 | 作用 |
|------|------|
| [dsh-wsl-docker](https://github.com/173787247/dsh-wsl-docker) | `docker_doctor`：Docker Desktop 与 WSL context 混淆 |
| [dsh-wsl-ssh-agent](https://github.com/173787247/dsh-wsl-ssh-agent) | `ssh_agent_hint`：把 Windows OpenSSH agent 转发进 WSL |
| [dsh-wsl-encoding](https://github.com/173787247/dsh-wsl-encoding) | `encoding_doctor`：UTF-8 与 Windows 代码页问题 |
| [dsh-wsl-wslconfig](https://github.com/173787247/dsh-wsl-wslconfig) | `wslconfig_hint`：只读建议 `.wslconfig` 内存 / mirrored 网络 |
| [dsh-wsl-download](https://github.com/173787247/dsh-wsl-download) | `win_download`：从 Windows「下载」拷到 WSL 工作区 |

可选相关：[session-contract](https://github.com/173787247/session-contract)。

## 推荐安装组合

| 组合 | 内容 |
|------|------|
| **最小** | env、net、open、repeat-stop |
| **日常** | 最小 + tool-budget、clipboard、path、browser、launch |
| **GitHub 日常** | 日常 + [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) + [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) |
| **WSL UI** | 日常 + workspace、picker、tray、expose |
| **诊断** | WSL UI + hostsvc、clock、dns、mnt、editor、shot |
| **完整** | [`install.sh`](./install.sh) 全部（含二梯队） |

## 安装

**前提：** 已安装 DeepSeek Harness；WSL 里 `dsh` 可用；配置文件一般是 `web`。

一键（从 GitHub 拉插件）：

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh | bash
# 或克隆本仓后：
bash install.sh
# 可选：DSH_PROFILE=web bash install.sh
```

本地检出示例：

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

然后：

1. 重启 `dsh web`。
2. 开一个**新会话**（旧会话仍是旧 prompt / 工具集）。
3. 可选：把 [`cordis.patch.yml`](./cordis.patch.yml) 合并进你的 profile。  
   **注意：** 后写的插件 `config` 会**整段替换**，需要的键都要重新写全。

## 建议的启动方式（Node 24 + Windows 代理）

若 Clash / V2Ray 在 Windows、WSL 要走代理：

```sh
export HTTP_PROXY=http://127.0.0.1:7890   # 改成你的端口
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
dsh web
```

API / npm 仍不通时，让 Agent 跑 `net_doctor`。

## 冒烟验证

| 检查 | 怎么看 |
|------|--------|
| env | Trajectory → SYSTEM → System Prompt → 搜 `Windows Subsystem for Linux` |
| net | 工具列表有 `net_doctor`；让 Agent 探测 DeepSeek / npm |
| open | Agent 写到 `/home/...` 下的路径可点击 |
| clipboard | 让 Agent 把路径拷到 Windows 剪贴板 |
| path | 让 Agent 转换 `/mnt/c/Users/...` ↔ `C:\Users\...` |
| repeat-stop / budget | 连续刷同一工具 → Trajectory 出现 `dsh-*-*: blocked` |
| github | 工具列表有 `github_app_hint` / `github_repo_status`；加载 App 环境后查当前仓库状态 |

## 安全提示

- 插件与 Harness 同权（读文件、联网、经 PowerShell 调 Windows）。
- `win_launch` 有白名单，扩 `allowlist` 时请谨慎。
- `cred_hint` 只给配置建议，不回传 token。
- `github_repo_status` 只在内存里换 GitHub App token，私钥不要贴进对话。
- `win_notify` 会阻塞弹出 MessageBox，文案勿含密钥。

## Topics

`deepseek-harness` · `dsh-plugin` · `wsl` · `github-app`

## 许可

MIT（与各子插件相同）。
