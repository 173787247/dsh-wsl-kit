# Snippet for [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)

Add under **Contents** and as a new section (English `README.md` + Chinese `README.zh.md`).

## Contents TOC line

```markdown
  - [WSL Kit (Windows + WSL)](#wsl-kit-windows--wsl)
```

## Section (English)

```markdown
## WSL Kit (Windows + WSL)

Browser on Windows, agent in WSL. Install the meta pack first: [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit).

- [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit) - One-click docs + `cordis.patch.yml` for the full WSL suite.
- [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) - Inject WSL/Windows path and shell facts into the system prompt.
- [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) - `net_doctor` tool: proxy / Node 24 fetch / DeepSeek+npm probes + copy-paste fix scripts.
- [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) - Proxy-aware `web_fetch` for WSL (undici ProxyAgent through Windows Clash; ≥0.1.1 retries + www↔apex).
- [dsh-wsl-obscura](https://github.com/173787247/dsh-wsl-obscura) - Optional Obscura headless tools from WSL (not Daily `KIT_SET`; not a `web_fetch` replacement).
- [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) - Click Linux paths in chat to open them in Windows.
- [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) - Read/write the Windows clipboard from WSL.
- [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) - Launch allowlisted Windows apps (`code`, Explorer, browsers…).
- [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) - Convert Linux ↔ Windows paths with `/mnt/c` caveats.
- [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) - Open http(s) URLs in the Windows default browser.
- [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) - Windows MessageBox when a long WSL task finishes.
- [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) - GitHub App: current-repo open PRs + latest Actions (no secrets).
- [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) - Probe nvidia-smi / GPU visibility inside WSL.
- [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) - Port listen + Windows localhost forwarding doctor.
- [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) - Current distro / multi-distro warnings.
- [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) - Safe Git Credential Manager hints (no secrets).
- [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) - Hard-stop consecutive identical tool calls.
- [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) - Hard-stop after a per-session tool-call budget.

### Optional Linux / local (not in `install.sh`)

Not shipped by Daily. Full catalog: [OPTIONAL_PLUGINS.md](https://github.com/173787247/dsh-wsl-kit/blob/master/docs/OPTIONAL_PLUGINS.md). Batch-link: `bash scripts/link-linux-plugins.sh`.

- [dsh-wsl-ollama](https://github.com/173787247/dsh-wsl-ollama) - Local Ollama: status / list / chat / embed.
- [dsh-wsl-llamacpp](https://github.com/173787247/dsh-wsl-llamacpp) - OpenAI-compatible llama.cpp / Unsloth Desktop client (default :8080).
- [dsh-wsl-vllm](https://github.com/173787247/dsh-wsl-vllm) - OpenAI-compatible vLLM client (default :8000).
- [dsh-wsl-vecmem](https://github.com/173787247/dsh-wsl-vecmem) - Tiny local vector memory via Ollama embeddings.
- [dsh-wsl-media](https://github.com/173787247/dsh-wsl-media) - Local media/doc pipeline: probe, extract, PDF, ASR, OCR.
- [dsh-wsl-search](https://github.com/173787247/dsh-wsl-search) - Sandboxed ripgrep / fd / ast-grep.
- [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) - Read-only pass / age secrets (allowPrefixes).
- [dsh-wsl-struct](https://github.com/173787247/dsh-wsl-struct) - Sandboxed jq / yq / read-only sqlite3.
- [dsh-wsl-git](https://github.com/173787247/dsh-wsl-git) - Capped git status / diff --stat (no full patches).
- [dsh-wsl-tmux](https://github.com/173787247/dsh-wsl-tmux) - Read-only tmux list + capture-pane.
- [dsh-wsl-compose](https://github.com/173787247/dsh-wsl-compose) - docker compose ps/logs; up/down double-gated.
- [dsh-wsl-systemd](https://github.com/173787247/dsh-wsl-systemd) - systemd --user read-only list / show / journal.
- [dsh-wsl-k8s](https://github.com/173787247/dsh-wsl-k8s) - Read-only kubectl get / describe / logs.
- [dsh-wsl-helm](https://github.com/173787247/dsh-wsl-helm) - Read-only helm list / status / history.
- [dsh-wsl-terraform](https://github.com/173787247/dsh-wsl-terraform) - terraform/tofu plan summary + state list (never apply).
- [dsh-wsl-rclone](https://github.com/173787247/dsh-wsl-rclone) - Read-only rclone listremotes / lsf / about.
- [dsh-wsl-db](https://github.com/173787247/dsh-wsl-db) - Read-only psql + redis-cli probes.
- [dsh-wsl-glab](https://github.com/173787247/dsh-wsl-glab) - Read-only glab MR / issue / ci status.
- [dsh-wsl-playwright](https://github.com/173787247/dsh-wsl-playwright) - Headless Playwright fetch (title + body) in WSL.
- [dsh-wsl-mail](https://github.com/173787247/dsh-wsl-mail) - Mail list/search via himalaya / notmuch (no send).
- [dsh-wsl-cal](https://github.com/173787247/dsh-wsl-cal) - Read-only khal calendar list.
- [dsh-wsl-pkg](https://github.com/173787247/dsh-wsl-pkg) - Dependency tree summaries: npm / pip / cargo.
- [dsh-wsl-im](https://github.com/173787247/dsh-wsl-im) - Optional IM bridge companion (not Daily).
- [dsh-wsl-obsidian](https://github.com/173787247/dsh-wsl-obsidian) - WSL agent ↔ Windows Obsidian vault read/write/open.
- [dsh-wsl-jev](https://github.com/173787247/dsh-wsl-jev) - Typed evidence questions via OpenRouter / Typesafe.
```

## 中文章节

```markdown
## WSL Kit（Windows + WSL）

浏览器在 Windows、Agent 在 WSL。建议先装元仓：[dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit)。

- [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit) - 一键文档 + 整套 `cordis.patch.yml`。
- [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) - 向 system prompt 注入 WSL/Windows 路径与 shell 事实。
- [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) - `net_doctor`：代理 / Node 24 fetch / DeepSeek+npm 探测 + 可复制修复脚本。
- [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) - 让 `web_fetch` 走 Windows 代理（不再直连公网 IP；≥0.1.1 重试 + www↔裸域）。
- [dsh-wsl-obscura](https://github.com/173787247/dsh-wsl-obscura) - 可选：WSL 驱动 Obscura 无头浏览器（不在 Daily；不替代 `web_fetch`）。
- [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) - 聊天里的 Linux 路径一键用 Windows 打开。
- [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) - 从 WSL 读写 Windows 剪贴板。
- [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) - 白名单启动 Windows 应用。
- [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) - Linux ↔ Windows 路径转换与 `/mnt/c` 注意点。
- [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) - 在 Windows 默认浏览器打开 http(s)。
- [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) - 长任务结束后弹出 Windows 提示框。
- [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) - GitHub App：当前仓库未关闭 PR + 最近一次 Actions（不回传密钥）。
- [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) - 探测 WSL 内 nvidia-smi / GPU。
- [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) - 端口监听与 Windows localhost 转发诊断。
- [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) - 当前发行版 / 多 distro 提醒。
- [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) - Git Credential Manager 安全指引（不回传密钥）。
- [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) - 连续相同工具调用硬拦截。
- [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) - 会话级工具调用次数上限硬拦截。

### 可选 Linux / 本地（不在 `install.sh`）

不进 Daily。完整目录：[OPTIONAL_PLUGINS.zh.md](https://github.com/173787247/dsh-wsl-kit/blob/master/docs/OPTIONAL_PLUGINS.zh.md)。批量链接：`bash scripts/link-linux-plugins.sh`。

- [dsh-wsl-ollama](https://github.com/173787247/dsh-wsl-ollama) - 本机 Ollama：status / list / chat / embed。
- [dsh-wsl-llamacpp](https://github.com/173787247/dsh-wsl-llamacpp) - 对接 llama.cpp / Unsloth Desktop 的 OpenAI 兼容接口（默认 :8080）。
- [dsh-wsl-vllm](https://github.com/173787247/dsh-wsl-vllm) - 对接本机/Docker vLLM 的 OpenAI 兼容服务（默认 :8000）。
- [dsh-wsl-vecmem](https://github.com/173787247/dsh-wsl-vecmem) - 本地向量小记：Ollama embedding + `~/.dsh/vecmem`。
- [dsh-wsl-media](https://github.com/173787247/dsh-wsl-media) - 本地媒体/文档管线：抽音轨、PDF、ASR、OCR 等。
- [dsh-wsl-search](https://github.com/173787247/dsh-wsl-search) - 沙箱 ripgrep / fd / ast-grep。
- [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) - 只读 pass / age 密钥（需 allowPrefixes）。
- [dsh-wsl-struct](https://github.com/173787247/dsh-wsl-struct) - 沙箱 jq / yq / sqlite3（只读 SELECT）。
- [dsh-wsl-git](https://github.com/173787247/dsh-wsl-git) - 截断版 git status / diff --stat，避免巨型 diff。
- [dsh-wsl-tmux](https://github.com/173787247/dsh-wsl-tmux) - 只读查看 tmux 会话与 pane 输出。
- [dsh-wsl-compose](https://github.com/173787247/dsh-wsl-compose) - docker compose：ps/logs；up/down 需双重确认。
- [dsh-wsl-systemd](https://github.com/173787247/dsh-wsl-systemd) - systemd --user 只读：list / show / journal。
- [dsh-wsl-k8s](https://github.com/173787247/dsh-wsl-k8s) - kubectl 只读：get / describe / logs。
- [dsh-wsl-helm](https://github.com/173787247/dsh-wsl-helm) - Helm 只读：list / status / history。
- [dsh-wsl-terraform](https://github.com/173787247/dsh-wsl-terraform) - terraform/tofu：plan 摘要 + state list（永不 apply）。
- [dsh-wsl-rclone](https://github.com/173787247/dsh-wsl-rclone) - rclone 只读：listremotes / lsf / about。
- [dsh-wsl-db](https://github.com/173787247/dsh-wsl-db) - psql / redis-cli 只读探针。
- [dsh-wsl-glab](https://github.com/173787247/dsh-wsl-glab) - GitLab CLI（glab）只读：MR / issue / ci。
- [dsh-wsl-playwright](https://github.com/173787247/dsh-wsl-playwright) - WSL 无头 Playwright 抓取页面标题与正文。
- [dsh-wsl-mail](https://github.com/173787247/dsh-wsl-mail) - 邮件只读：himalaya list / notmuch search。
- [dsh-wsl-cal](https://github.com/173787247/dsh-wsl-cal) - 日历只读：khal list / today。
- [dsh-wsl-pkg](https://github.com/173787247/dsh-wsl-pkg) - 依赖树摘要：npm ls / pip list / cargo tree。
- [dsh-wsl-im](https://github.com/173787247/dsh-wsl-im) - 可选 IM 桥接（不在 Daily）。
- [dsh-wsl-obsidian](https://github.com/173787247/dsh-wsl-obsidian) - WSL ↔ Windows Obsidian 仓库读写与打开。
- [dsh-wsl-jev](https://github.com/173787247/dsh-wsl-jev) - 经 OpenRouter / Typesafe 的 typed 证据问答。
```
