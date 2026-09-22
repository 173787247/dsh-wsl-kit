# -*- coding: utf-8 -*-
"""Expand Chinese-first + English READMEs for optional Linux plugins; write kit catalog."""
from pathlib import Path

BASE = Path(r"c:\Users\rchua\Desktop\AIFullStackDevelopment")
KIT = BASE / "dsh-wsl-kit"

# name -> {ver, one_zh, one_en, tools: [(tool, zh, en)], notes_zh, notes_en, config_zh, config_en}
CATALOG = {
  "dsh-wsl-llamacpp": {
    "ver": "0.1.0",
    "one_zh": "对接本机 llama.cpp / Unsloth Desktop 的 OpenAI 兼容接口（默认 :8080）。",
    "one_en": "OpenAI-compatible client for llama.cpp / Unsloth Desktop (default :8080).",
    "tools": [
      ("llama_status", "是否可达、模型 id", "reachability + model ids"),
      ("llama_chat", "/v1/chat/completions", "chat completions"),
    ],
    "notes_zh": "复用已有 GGUF，不重装工具链。环境变量：`DSH_LLAMA_BASE`、`DSH_LLAMA_MODEL`。",
    "notes_en": "Reuse existing GGUF servers. Env: `DSH_LLAMA_BASE`, `DSH_LLAMA_MODEL`.",
    "config": "baseUrl / defaultModel / timeoutMs",
  },
  "dsh-wsl-vllm": {
    "ver": "0.1.0",
    "one_zh": "对接本机/Docker vLLM 的 OpenAI 兼容服务（默认 :8000）。",
    "one_en": "OpenAI-compatible vLLM client (default :8000).",
    "tools": [
      ("vllm_status", "可达性与模型", "reachability + models"),
      ("vllm_chat", "对话补全", "chat completions"),
    ],
    "notes_zh": "Windows 原生 vLLM 一般没有；优先 Docker。`DSH_VLLM_BASE` / `DSH_VLLM_MODEL`。",
    "notes_en": "Prefer Docker/AI1 history over Windows-native vLLM. Env: `DSH_VLLM_BASE`, `DSH_VLLM_MODEL`.",
    "config": "baseUrl / defaultModel / timeoutMs",
  },
  "dsh-wsl-struct": {
    "ver": "0.1.0",
    "one_zh": "沙箱化 jq / yq / sqlite3（只读 SELECT）。",
    "one_en": "Sandboxed jq / yq / read-only sqlite3.",
    "tools": [
      ("struct_status", "CLI 是否在 PATH", "CLI on PATH"),
      ("struct_jq", "jq 过滤", "jq filter"),
      ("struct_yq", "yq 查询", "yq expression"),
      ("struct_sqlite", "只读 SQL", "SELECT-only SQL"),
    ],
    "notes_zh": "默认根：`$HOME`、`~/.dsh`、`/tmp`。禁止破坏性 SQL。",
    "notes_en": "Default roots: `$HOME`, `~/.dsh`, `/tmp`. Mutating SQL refused.",
    "config": "allowRoots / timeoutMs",
  },
  "dsh-wsl-git": {
    "ver": "0.1.0",
    "one_zh": "截断版 git status / diff --stat，避免巨型 diff 灌上下文。",
    "one_en": "Capped git status / diff --stat (no full patches).",
    "tools": [
      ("git_tool_status", "git 是否可用", "git on PATH"),
      ("git_status_summary", "status -sb + 变更数", "short status + count"),
      ("git_diff_stat", "仅 --stat", "diff --stat only"),
    ],
    "notes_zh": "不提供 commit / push。",
    "notes_en": "No commit/push.",
    "config": "allowRoots / timeoutMs",
  },
  "dsh-wsl-tmux": {
    "ver": "0.1.0",
    "one_zh": "只读查看 tmux 会话与 pane 输出。",
    "one_en": "Read-only tmux list + capture-pane.",
    "tools": [
      ("tmux_status", "tmux/screen 是否可用", "tmux/screen on PATH"),
      ("tmux_list", "列会话", "list sessions"),
      ("tmux_capture", "capture-pane", "capture pane text"),
    ],
    "notes_zh": "不发送按键、不杀会话。",
    "notes_en": "No send-keys / kill-session.",
    "config": "timeoutMs",
  },
  "dsh-wsl-compose": {
    "ver": "0.1.0",
    "one_zh": "docker compose：ps/logs；up/down 需双重确认。",
    "one_en": "docker compose ps/logs; up/down double-gated.",
    "tools": [
      ("compose_status", "docker 是否可用", "docker on PATH"),
      ("compose_ps", "compose ps", "compose ps"),
      ("compose_logs", "日志尾", "log tail"),
      ("compose_up", "up -d（危险）", "up -d (dangerous)"),
      ("compose_down", "down（危险）", "down (dangerous)"),
    ],
    "notes_zh": "默认 `allowMutate: false`。变更必须 `allowMutate=true` 且工具参数 `confirm=true`。互补 `docker_doctor`。",
    "notes_en": "Default `allowMutate: false`. Mutations need config + `confirm=true`. Complements `docker_doctor`.",
    "config": "allowRoots / allowMutate / timeoutMs",
  },
  "dsh-wsl-systemd": {
    "ver": "0.1.0",
    "one_zh": "systemd --user 只读：list / show / journal。",
    "one_en": "systemd --user read-only list/show/journal.",
    "tools": [
      ("systemd_status", "systemctl 是否可用", "systemctl on PATH"),
      ("systemd_user_list", "用户服务列表", "list user units"),
      ("systemd_user_show", "单元状态", "show unit"),
      ("systemd_user_journal", "近期日志", "journal tail"),
    ],
    "notes_zh": "不能 start/stop/enable。适合查 Ollama 等用户单元。",
    "notes_en": "No start/stop/enable. Useful for Ollama user units.",
    "config": "timeoutMs",
  },
  "dsh-wsl-helm": {
    "ver": "0.1.0",
    "one_zh": "Helm 只读：list / status / history。",
    "one_en": "Read-only helm list/status/history.",
    "tools": [
      ("helm_status_tool", "helm 版本", "helm version"),
      ("helm_list", "release 列表", "list releases"),
      ("helm_release_status", "release 状态", "release status"),
      ("helm_history", "历史", "history"),
    ],
    "notes_zh": "禁止 install/upgrade/uninstall。可配 `allowedContexts`。",
    "notes_en": "No install/upgrade/uninstall. Optional `allowedContexts`.",
    "config": "allowedContexts / maxOutputChars / timeoutMs",
  },
  "dsh-wsl-terraform": {
    "ver": "0.1.0",
    "one_zh": "terraform/tofu：plan 摘要 + state list（永不 apply）。",
    "one_en": "terraform/tofu plan summary + state list (never apply).",
    "tools": [
      ("tf_status", "terraform/tofu 是否可用", "binaries on PATH"),
      ("tf_plan_summary", "plan 计数摘要", "Plan add/change/destroy"),
      ("tf_state_list", "state list", "state list"),
    ],
    "notes_zh": "只读。输出截断。建议配 `allowRoots`。",
    "notes_en": "Read-only, capped output. Prefer `allowRoots`.",
    "config": "allowRoots / timeoutMs",
  },
  "dsh-wsl-rclone": {
    "ver": "0.1.0",
    "one_zh": "rclone 只读：listremotes / lsf / about。",
    "one_en": "Read-only rclone listremotes / lsf / about.",
    "tools": [
      ("rclone_status", "rclone 是否可用", "rclone on PATH"),
      ("rclone_listremotes", "远程名列表", "list remotes"),
      ("rclone_lsf", "列远程文件", "list remote files"),
      ("rclone_about", "用量/配额", "about/quota"),
    ],
    "notes_zh": "无 copy/sync/delete。建议 `allowedRemotes` 限制 egress。勿把 rclone.conf 密钥贴进聊天。",
    "notes_en": "No copy/sync/delete. Prefer `allowedRemotes`. Never paste rclone.conf secrets.",
    "config": "allowedRemotes / timeoutMs",
  },
  "dsh-wsl-db": {
    "ver": "0.1.0",
    "one_zh": "psql / redis-cli 只读探针。",
    "one_en": "Read-only psql + redis-cli probes.",
    "tools": [
      ("db_status", "CLI 与连接别名", "CLIs + connection aliases"),
      ("db_psql", "SELECT/WITH/SHOW/EXPLAIN", "read-only SQL"),
      ("db_redis", "PING/GET/INFO/SCAN…", "read-only redis cmds"),
    ],
    "notes_zh": "用 `config.connections` 命名 URI；默认禁止任意 URL。`redisHosts` 白名单。",
    "notes_en": "Named URIs in `config.connections`; `allowAnyUrl` off by default. `redisHosts` allowlist.",
    "config": "connections / allowAnyUrl / redisHosts / timeoutMs",
  },
  "dsh-wsl-glab": {
    "ver": "0.1.0",
    "one_zh": "GitLab CLI（glab）只读：MR / issue / ci status。",
    "one_en": "Read-only glab MR/issue/ci status.",
    "tools": [
      ("glab_status", "glab 版本", "glab version"),
      ("glab_mr_list", "MR 列表", "MR list"),
      ("glab_issue_list", "Issue 列表", "issue list"),
      ("glab_ci_status", "流水线状态", "ci status"),
    ],
    "notes_zh": "不创建/合并 MR。认证走 glab 自己的配置。互补 `dsh-wsl-github`。",
    "notes_en": "No create/merge. Auth via glab config. Complements `dsh-wsl-github`.",
    "config": "timeoutMs",
  },
  "dsh-wsl-playwright": {
    "ver": "0.1.0",
    "one_zh": "WSL 无头 Playwright 抓取页面标题与正文。",
    "one_en": "Headless Playwright fetch (title + body text) in WSL.",
    "tools": [
      ("pw_status", "npx/node 是否可用", "npx/node available"),
      ("pw_fetch", "无头打开 URL", "headless fetch URL"),
    ],
    "notes_zh": "交互浏览优先 `dsh-wsl-browser`（Windows）。同一任务不要双轨驱动。首次可能经 npx 下载浏览器。",
    "notes_en": "Prefer `dsh-wsl-browser` for interactive Windows browsing. Do not dual-drive. First run may download browsers via npx.",
    "config": "timeoutMs / maxChars",
  },
  "dsh-wsl-mail": {
    "ver": "0.1.0",
    "one_zh": "邮件只读：himalaya list / notmuch search。",
    "one_en": "Mail list/search via himalaya / notmuch (no send).",
    "tools": [
      ("mail_status", "CLI 是否可用", "CLIs on PATH"),
      ("mail_list", "himalaya 信封列表", "himalaya envelopes"),
      ("mail_notmuch", "notmuch 搜索", "notmuch search"),
    ],
    "notes_zh": "不发送、不删除。自行配置 himalaya/notmuch；勿贴 IMAP 密码。",
    "notes_en": "No send/delete. Configure himalaya/notmuch yourself; never paste IMAP passwords.",
    "config": "timeoutMs",
  },
  "dsh-wsl-cal": {
    "ver": "0.1.0",
    "one_zh": "日历只读：khal list / today。",
    "one_en": "Read-only khal calendar list.",
    "tools": [
      ("cal_status", "khal 是否可用", "khal on PATH"),
      ("cal_today", "今天日程", "today"),
      ("cal_list", "未来 N 天", "next N days"),
    ],
    "notes_zh": "不创建/修改事件。自行配置 khal。",
    "notes_en": "No create/modify. Configure khal yourself.",
    "config": "timeoutMs",
  },
  "dsh-wsl-pkg": {
    "ver": "0.1.0",
    "one_zh": "依赖树摘要：npm ls / pip list / cargo tree。",
    "one_en": "Dependency tree summaries: npm / pip / cargo.",
    "tools": [
      ("pkg_status", "包管理器是否可用", "managers on PATH"),
      ("pkg_npm_ls", "npm ls 浅摘要", "shallow npm ls"),
      ("pkg_pip_list", "pip list", "pip list"),
      ("pkg_cargo_tree", "cargo tree -d 1", "cargo tree depth 1"),
    ],
    "notes_zh": "不安装/卸载。深度默认很浅，避免噪音。",
    "notes_en": "No install/uninstall. Shallow by default to avoid noise.",
    "config": "allowRoots / timeoutMs",
  },
  "dsh-wsl-media": {
    "ver": "0.2.0",
    "one_zh": "本地媒体/文档管线：ffprobe、抽音轨、缩略图、PDF、ASR、pandoc、OCR、exif。",
    "one_en": "Local media/doc pipeline: probe, extract, thumbnail, PDF, ASR, pandoc, OCR, exif.",
    "tools": [
      ("media_status", "CLI 探测", "CLI probe"),
      ("media_probe", "ffprobe", "ffprobe"),
      ("media_extract_audio", "抽音轨", "extract audio"),
      ("media_thumbnail", "缩略图", "thumbnail"),
      ("media_pdf_text", "PDF 文本", "PDF text"),
      ("media_asr", "whisper ASR", "whisper ASR"),
      ("media_pandoc", "格式转换", "pandoc convert"),
      ("media_ocr", "tesseract OCR", "tesseract OCR"),
      ("media_exif", "exiftool", "exiftool"),
    ],
    "notes_zh": "路径必须在 allowRoots（默认含家目录、`/tmp`、`/mnt/c|d`）。",
    "notes_en": "Paths must stay under allowRoots (home, `/tmp`, `/mnt/c|d` by default).",
    "config": "allowRoots / timeoutMs / maxPdfChars",
  },
}


def write_pair(name: str, meta: dict) -> None:
    d = BASE / name
    tools_zh = "\n".join(f"| `{t}` | {z} |" for t, z, _ in meta["tools"])
    tools_en = "\n".join(f"| `{t}` | {e} |" for t, _, e in meta["tools"])
    zh = f"""# {name}

> **语言：** **中文**（本页） · [English](./README.en.md)

{meta['one_zh']}

| | |
|---|---|
| 版本 | **{meta['ver']}** |
| 套件 | [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit) **可选**，不在 `install.sh` |

## 安装

```sh
dsh plugin --profile web add github:173787247/{name}
# 或本机 path：
# dsh plugin --profile web add /mnt/c/Users/YOU/Desktop/AIFullStackDevelopment/{name}
```

kit 批量链接（可选）：`bash dsh-wsl-kit/scripts/link-linux-plugins.sh`

## 工具

| 工具 | 作用 |
|------|------|
{tools_zh}

## 配置要点

`{meta['config']}`

{meta['notes_zh']}

## License

MIT
"""
    en = f"""# {name}

> **Languages:** [中文（首页）](./README.md) · **English** (this file)

{meta['one_en']}

| | |
|---|---|
| Version | **{meta['ver']}** |
| Kit | Optional companion to [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit); not in `install.sh` |

## Install

```sh
dsh plugin --profile web add github:173787247/{name}
```

Batch link (optional): `bash dsh-wsl-kit/scripts/link-linux-plugins.sh`

## Tools

| Tool | Role |
|------|------|
{tools_en}

## Config

`{meta['config']}`

{meta['notes_en']}

## License

MIT
"""
    stub = f"""# {name} — 中文说明

中文已作为仓库首页：**[README.md](./README.md)**。

English: [README.en.md](./README.en.md)
"""
    (d / "README.md").write_text(zh, encoding="utf-8")
    (d / "README.en.md").write_text(en, encoding="utf-8")
    (d / "README.zh.md").write_text(stub, encoding="utf-8")
    print("docs", name)


def write_kit_catalog() -> None:
    rows_zh = []
    rows_en = []
    for name, m in CATALOG.items():
        url = f"https://github.com/173787247/{name}"
        rows_zh.append(f"| [{name}]({url}) | {m['ver']} | {m['one_zh']} |")
        rows_en.append(f"| [{name}]({url}) | {m['ver']} | {m['one_en']} |")
    zh = f"""# 可选 Linux / 本地能力插件一览

> 这些插件**不在** `install.sh` / Daily 套件。浏览器在 Windows、agent 在 WSL 时按需安装。  
> 每个仓首页为中文 `README.md`，英文见 `README.en.md`。

总览也写在 [README.zh.md](../README.zh.md) 的「GitHub 附加与可选」与「kit 之外怎么长」。

## 目录

| 插件 | 版本 | 一句话 |
|------|------|--------|
{chr(10).join(rows_zh)}

另见早期可选：`dsh-wsl-ollama` / `search` / `vecmem` / `k8s` / `secret` / `jev` / `obsidian` / `im`（已在主 README 表内）。

## 批量链接到 web profile

```sh
bash scripts/link-linux-plugins.sh
```

默认链接一整组可选仓（可用环境变量 `DSH_LINK_PLUGINS` 覆盖名单）。

## License

与各子仓相同（MIT）。
"""
    en = f"""# Optional Linux / local capability plugins

> These are **not** in `install.sh` / Daily. Install as needed when the browser is on Windows and the agent is in WSL.  
> Each repo homepage is Chinese `README.md`; English is `README.en.md`.

Also listed in the main [README.md](../README.md) optional table and Beyond section.

## Catalog

| Plugin | Ver | Summary |
|--------|-----|---------|
{chr(10).join(rows_en)}

Also: `dsh-wsl-ollama` / `search` / `vecmem` / `k8s` / `secret` / `jev` / `obsidian` / `im` (in the main README tables).

## Batch-link into web profile

```sh
bash scripts/link-linux-plugins.sh
```

Override the list with `DSH_LINK_PLUGINS` (space-separated).

## License

MIT (same as individual plugins).
"""
    docs = KIT / "docs"
    docs.mkdir(exist_ok=True)
    (docs / "OPTIONAL_PLUGINS.zh.md").write_text(zh, encoding="utf-8")
    (docs / "OPTIONAL_PLUGINS.md").write_text(en, encoding="utf-8")
    print("kit catalog written")


def main() -> None:
    for name, meta in CATALOG.items():
        write_pair(name, meta)
    write_kit_catalog()


if __name__ == "__main__":
    main()
