# DSH 插件新生事务队列（功能加深 / 改版）

对照：此前「kit 之外怎么长」里曾写 **暂缓** 的项，**现全部纳入推进**，不 park。  
awesome 收录见 [`AWESOME_QUEUE.zh.md`](./AWESOME_QUEUE.zh.md)（A–J 已合入）。本文件管 **产品加深**。

更新于 **2026-09-26**。

## 原则

1. 不新开重复仓；IM 继续单仓 `dsh-wsl-im`。
2. 每项有明确「下一交付」与目标版本号。
3. 安全默认优先于便利（白名单、只读、confirm）。
4. 薄 UX / 只读 DevOps **同样排期**，按 Wave 推进。

## 总览

| Wave | 主题 | 状态 |
|------|------|------|
| **K** | IM 安全/语音 · Mac 剪贴板 · remote-ssh 探针 | **完成** |
| **L** | IM↔media/vecmem 联动 · Mattermost · device 真机样例 | **完成** |
| **M** | 薄 UX：editor / shot / notify / picker | **完成** |
| **N** | Obsidian / ollama / search / secret 打磨 | **完成** |
| **O** | 只读 DevOps 加深（k8s→glab 族） | **完成** |
| **P** | 横切：companion 共用库 · kit 文档对齐 · 调用链文档 | **完成** |

---

## Wave K — 近端（完成）

| ID | 仓 | 下一交付 | 目标 |
|----|-----|----------|------|
| K1 | `dsh-wsl-im` | `requireAllowlist` / 启动警告 / `im_status.allowlistOpen` | 0.3.6 |
| K2 | `dsh-wsl-im` | 无平台 ASR 时尝试本机 whisper（`lib/local-asr.js`）；失败统一 UX | 0.3.6 |
| K3 | `dsh-mac-companion` | 暴露 `mac_clipboard_read`（可选 write+confirm） | 0.1.1 |
| K4 | `dsh-remote-ssh` | `remote_ssh_probe` 只读套装（uname/df/uptime/…） | 0.1.1 |
| K5 | kit | README 去掉「薄 UX 暂缓」；IM 版本对齐 0.3.x | 文档 |

## Wave L — IM 生态与设备

| ID | 仓 | 下一交付 |
|----|-----|----------|
| L1 | `dsh-wsl-im` + `dsh-wsl-media` | 语音落盘路径进 media allowRoots；文档化 ASR 调用链 |
| L2 | `dsh-wsl-im` + `dsh-wsl-vecmem` | 会话摘要可选 `vecmem_add`（workspace=im:{platform}） |
| L3 | `dsh-wsl-im` | Mattermost Outgoing Webhook + Bot REST adapter |
| L4 | `dsh-device-bridge` | Termux / 轻量 companion 样例 + 能力表扩展 |
| L5 | `dsh-mac-companion` / `device-bridge` | 抽出共用 `companion_client`（→ common 或小包） |

## Wave M — 薄 UX（原「暂缓」，现推进）

| ID | 仓 | 下一交付 |
|----|-----|----------|
| M1 | `dsh-wsl-editor` | `line` / `column` 打开；`win_editor_status` 探测可用编辑器 |
| M2 | `dsh-wsl-shot` | 无图时明确状态；可选 PNG 路径约定 |
| M3 | `dsh-wsl-notify` | `mode=toast\|messagebox`（非阻塞气球） |
| M4 | `dsh-wsl-picker` | 过滤 / 起始路径；列出 IM workspace 快捷入口 |

## Wave N — 知识与本地推理

| ID | 仓 | 下一交付 |
|----|-----|----------|
| N1 | `dsh-wsl-vecmem` | `workspace` 命名空间；按 workspace 检索/清理 |
| N2 | `dsh-wsl-obsidian` | wikilink 解析；写操作 confirm 门闩 |
| N3 | `dsh-wsl-ollama` | Windows 主机探测提示（503/`host.docker.internal`/网关） |
| N4 | `dsh-wsl-search` | 默认 allowRoots 含 `~/.dsh/im-workspace` |
| N5 | `dsh-wsl-jev` | 代理与 IM `proxiedFetch` 对齐；无 key 时友好 status |

## Wave O — 只读 DevOps（原「开仓即够」，现加深）

每仓至少加：**status 更丰** + **一条高频只读工具**（日志/列表/diff）。

| ID | 仓 | 下一交付 |
|----|-----|----------|
| O1 | `dsh-wsl-k8s` | `k8s_contexts`；`k8s_logs` 尾部行数上限 |
| O2 | `dsh-wsl-helm` | `helm_list` / `helm_status` 只读 |
| O3 | `dsh-wsl-terraform` | `terraform_plan` dry 探测 / state list 只读 |
| O4 | `dsh-wsl-compose` | `compose_ps` / `compose_logs` 只读 |
| O5 | `dsh-wsl-systemd` | `systemd_status` / `journal_tail` 只读 |
| O6 | `dsh-wsl-git` | `git_status_summary` / `git_log_oneline` |
| O7 | `dsh-wsl-tmux` | `tmux_list` / `tmux_capture` |
| O8 | `dsh-wsl-rclone` | `rclone_lsf` 只读 |
| O9 | `dsh-wsl-db` | `db_ping` / 只读 query 白名单 |
| O10 | `dsh-wsl-glab` | `glab_ci_status` 只读 |
| O11 | 桌面辅助 `playwright`/`mail`/`cal`/`pkg` | 各加一条「日常最高频」工具 |

## Wave P — 横切

| ID | 交付 |
|----|------|
| P1 | kit README「kit 之外」表：IM→当前版本；remote 三仓写入；去掉暂缓措辞 |
| P2 | `docs/CALL_CHAINS.zh.md`：IM 语音→ASR→vecmem；Mac/Win 剪贴板对称 |
| P3 | `proxiedFetch` 复用到 jev / companion HTTP |
| P4 | 出站 `im-plain` 评估企微/飞书是否需要 |

## 完成勾选（本机推进时改）

- [x] 本队列落盘
- [x] K1–K5 代码合入并推 GitHub（Wave K）
- [x] Wave L（media / Mattermost / vecmemOnReply / device / companion common）
- [x] Wave M（editor / shot / notify / picker）
- [x] Wave N（vecmem / obsidian / ollama / search / jev）
- [x] Wave O（DevOps 族加深）
- [x] Wave P（CALL_CHAINS · proxiedFetch · 文档对齐）
