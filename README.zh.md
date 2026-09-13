# dsh-wsl-kit

**一句话：** Agent 在 WSL 里跑 DeepSeek Harness，聊天在 Windows 浏览器——路径、代理、剪贴板、打开文件都要跨系统时，装这个套件。

本仓是**元仓**（文档 + 安装脚本 + [`cordis.patch.yml`](./cordis.patch.yml)），不含插件运行时代码。各子插件仓库另附英文 `README.md` 与中文 `README.zh.md`。

[English → README.md](./README.md)

---

## 兼容性（2026-09）

| 项 | 现状 |
|----|------|
| **dsh** | 已在 **`0.1.5-rc.1`** 验证（2026-09-10 时 npm `latest`；尚无非 rc 的 `0.1.5`）。脚本按 dsh **≥0.1.2** 的 UI 一次性 `?token=`（`:3081`）编写。 |
| **DeepSeek V4.1 Flash** | 官方 API 模型 id 为 **`deepseek-flash`**。旧名 `deepseek-v4-flash` / `deepseek-v4-flash-vision-exp` 暂时会路由到 V4.1 Flash。**本 kit 不写死模型**——在 `~/.dsh/settings.yaml` 的 `llm-deepseek` / 默认模型里改。 |
| **Agent Teams** | 可选实验包（`@deepseek-ai/dsh-experimental-agent-team-profile`，与 dsh 同版本线）。**不在** `install.sh` 里。开了 Teams 会出现更长的 “Deep diving”；测模型请先用普通新会话。 |
| **插件** | 版本地板见 [`scripts/check-plugin-versions.sh`](./scripts/check-plugin-versions.sh)。日常套件含 [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) **≥0.1.1**。 |

### 子插件 README 约定

- **本兼容表是套件矩阵唯一真源。** 各子插件 README（中英）都有对应的 **兼容性** 表：最低 dsh **≥0.1.2**、链回此处看**最新验证**、套件档位，并说明云端 Flash / Agent Teams 不归 WSL 插件管。
- 每当 dsh 发新线（如 `0.1.5` 正式版或 `0.1.6`），**先改本 kit 表**，再刷新各插件「当前 …」行（或跑文档同步）。没有冒烟通过就不要虚构「已验证」日期。
- API 敏感插件（`net` / `fetch` / `port` / `expose` / `tray` / `hostsvc`）另有 **范围** 段；薄 Daily 工具只保留共用表即可。

仅换到 V4.1 Flash **不必**改 kit 安装逻辑；若默认模型仍是已退役 id，改 settings 即可。

---

## 60 秒上手（推荐：日常套件）

**前提：** WSL 里已能运行 `dsh`（通常 profile = `web`）。建议 `0.1.5-rc.1` 或同系列更新。

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=daily bash
```

然后：

1. 用 [`scripts/restart-dsh-web.sh`](./scripts/restart-dsh-web.sh) 重启（`:3080` dsh + `:3081` Windows 中继）
2. Windows 浏览器打开 **`restart-dsh-web.sh` 打印的 URL**（dsh ≥0.1.2 带 `?token=`；裸 `:3081` 是 401。不要用 `:3080`）。Token 也写在 WSL `/tmp/dsh-ui-url`。
3. 开一个**新会话**（旧会话仍是旧工具集）
4. 可选：把 [`cordis.patch.yml`](./cordis.patch.yml) 合并进 profile（后写的插件 `config` 会**整段替换**，键要写全）

| 想装什么 | 命令 |
|----------|------|
| **日常（默认推荐）** | `KIT_SET=daily bash install.sh` |
| 日常 + GitHub App / 凭据 | `KIT_SET=github bash install.sh` |
| **本地 LLM + 网络诊断** | `KIT_SET=llm bash install.sh` |
| 全家桶 | `KIT_SET=full bash install.sh`（或不设 `KIT_SET`，兼容旧行为） |

本地克隆后：`KIT_SET=daily bash install.sh`

### `restart-dsh-web.sh` 会加载什么

- `NODE_USE_ENV_PROXY=1`，`OLLAMA_API_KEY` 默认 `ollama`
- `NO_PROXY` **仅** `127.0.0.1,localhost`（不要继承 Clash 的 RFC1918 `NO_PROXY` 通配，否则 Node 绕过代理，访问 `api.deepseek.com` 会 TRANSPORT 超时）
- GitHub App：启动前自行 `source "$HOME/.dsh/dsh-wsl-github.env"`

---

## 你马上能用的能力

| 痛点 | 工具 | 插件 |
|------|------|------|
| 代理 / Node 24 打不通 DeepSeek 或 npm | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| `web_fetch` 报 `TypeError: fetch failed`（API 却通） | 装 [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) ≥0.1.1 + `restart-dsh-web.sh` | [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) |
| 聊天里的 Linux 路径要在 Windows 打开 | （可点击路径） | [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) |
| 路径互转、`/mnt/c` 慢 | `path_convert` | [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) |
| 读写 Windows 剪贴板 | `wsl_clipboard` | [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) |
| 在 Windows 浏览器打开 PR / 文档链接 | `win_open_url` | [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) |
| Agent 不知道自己在 WSL | （注入 system prompt） | [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) |

**日常套件** = 上表 + `win_launch` + `dsh-repeat-stop` + `dsh-tool-budget` + **`dsh-wsl-fetch`**。

冒烟：对新会话说「跑一下 `net_doctor`」「把当前路径拷到 Windows 剪贴板」。云端优先选 **`deepseek-flash`**；第一次冒烟先关掉 Agent Teams。

---

## 安装组合（短名单）

| 组合 | 包含 | 适合谁 |
|------|------|--------|
| **日常** | env、net、**fetch**、open、repeat-stop、tool-budget、clipboard、path、browser、launch | 绝大多数 WSL + Windows 浏览器用户 |
| **GitHub 日常** | 日常 + [github](https://github.com/173787247/dsh-wsl-github) + [cred](https://github.com/173787247/dsh-wsl-cred) + notify | 还要查 PR/Actions、修 `git push` 凭据 |
| **本地 LLM** | env、net、**fetch**、hostsvc、docker、dns、clock、gpu、port、expose、tray、open、path、browser | Ollama / vLLM / Unsloth + 连通性 |
| **完整** | [`install.sh`](./install.sh) 全部 | 诊断 GPU/Docker/时钟、托盘启动、portproxy 等 |

**不要**一上来装完整套——先日常跑通，再按痛点加插件。

### GitHub 日常（可选）

WSL 里碰 GitHub = 凭据 + API + 浏览器打开 + 代理，不是一个大插件能糊弄的。装 `KIT_SET=github` 后：

1. 按 [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github/blob/master/README.zh.md) 创建 GitHub App（只读 Metadata / PR / Actions，关 webhook）
2. 启动前：`source "$HOME/.dsh/dsh-wsl-github.env"`
3. 新会话里跑 `github_app_hint` / `github_repo_status`；**不要**把 PEM / PAT 贴进聊天

---

## Node 24 + Windows 代理

Clash / V2Ray 在 Windows、WSL 要走代理时：

```sh
export HTTP_PROXY=http://127.0.0.1:7890   # 或 Clash mixed，如 16006
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
# 推荐用 restart-dsh-web.sh，保证 NO_PROXY 只有回环
```

仍不通 → 让 Agent 跑 `net_doctor`。

- **API 通、`web_fetch` 失败** → [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch)（日常套件已装）。
- **第三方 Workers / Cloudflare 经 Clash 返回 403（1010）** → 对该域名加 Clash **DIRECT**（插件改不了站点 WAF）。

本地 Ollama / LM Studio 等在 Windows 上：加 [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc)，跑 `host_reach`，再合并 [`examples/local-llm-providers.settings.yaml`](./examples/local-llm-providers.settings.yaml)。

---

## 故障树

连不上 Ollama、API、git push、`web_fetch` 时先看 **[docs/TROUBLESHOOTING.zh.md](./docs/TROUBLESHOOTING.zh.md)**（英文：[TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)）。

推荐顺序：`host_reach` → `net_doctor` → `dns_doctor` → `clock_doctor` → workspace/mnt → expose（仅 LAN）。

---

## 完整插件目录（按需查阅）

<details>
<summary>点击展开全部插件表</summary>

### 日常（KIT_SET=daily）

| 插件 | 作用 |
|------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | 向 system prompt 注入 WSL/Windows 事实 |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` |
| [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) | 让 `web_fetch` 走 Windows 代理（undici `ProxyAgent`） |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | 聊天路径在 Windows 打开 |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | 连续相同工具调用硬拦截 |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | 会话级工具次数上限 |
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard` |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert` |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch`（白名单） |

### GitHub 附加

| 插件 | 作用 |
|------|------|
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_app_hint` / `github_repo_status` |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint`（不输出密钥） |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify` |

### 诊断 / UI / 二梯队

| 插件 | 作用 |
|------|------|
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

可选相关：[session-contract](https://github.com/173787247/session-contract)。awesome 片段：[`awesome-wsl-kit.md`](./awesome-wsl-kit.md)。

**Awesome 现状（2026-09）：** `173787247` 下已收录 **32** 个插件（含 [fetch](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/blob/main/data/plugins/173787247__dsh-wsl-fetch.yml) [#4736](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/4736)、[obscura](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/blob/main/data/plugins/173787247__dsh-wsl-obscura.yml) [#4903](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/4903)）。**本 kit 元仓不进 awesome** — 用本仓 / `install.sh` 安装。

</details>

---

## kit 之外怎么长

| 方向 | 建议 | 状态 |
|------|------|------|
| dsh 0.1.5-rc.1 + `deepseek-flash` | 文档 / settings；安装路径不变 | 本轮文档 |
| Daily/LLM 含 fetch ≥0.1.2 | 重试、共享 ProxyAgent、www↔apex、失败 advice | 已做；[awesome 已收录](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/blob/main/data/plugins/173787247__dsh-wsl-fetch.yml) |
| `dsh-wsl-obscura`（可选） | Obscura 无头工具；不在 Daily `KIT_SET` | 已做；[awesome 已收录](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/blob/main/data/plugins/173787247__dsh-wsl-obscura.yml) |
| 套件 awesome 盘点 | 插件 32 条；**kit 本身不收录** | 当前 |
| 安装漂移治理 | [`check-plugin-versions.sh`](./scripts/check-plugin-versions.sh) | ✅ |
| 启动健康 | `check-dsh-health` 认 401 + tray token URL | ✅ |
| 本地推理探测 | `hostsvc` `apiReady` + `docker` HTTP 404 | ✅ |
| 浏览器打不开 | `port` / `expose` + dsh ≥0.1.2 鉴权 | ✅ |
| UX 薄插件加深 | editor / shot / notify / picker | **暂缓** |
| Agent Teams | 上游实验包，不进 kit | 范围外 |
| MCP / 钉钉 / OpenClaw | 独立产品线 | **别硬塞进 WSL 分类** |

原则：**该开新仓才开**；默认继续做深现有插件 + kit 文档。

---

## 安全

- 插件与 Harness 同权（读文件、联网、经 PowerShell 调 Windows）。
- `win_launch` 有白名单；`cred_hint` / GitHub App **不**把密钥贴进对话。
- `win_notify` 会阻塞弹窗，文案勿含密钥。
- `~/.dsh/*.env` 保持 `chmod 600`，勿把 API Key 提交进仓库。

## Topics

`deepseek-harness` · `dsh-plugin` · `wsl` · `windows` · `github-app`

## 许可

MIT（与各子插件相同）。
