# 可选 Linux / 本地能力插件一览

> 这些插件**不在** `install.sh` / Daily 套件。浏览器在 Windows、agent 在 WSL 时按需安装。  
> 每个仓首页为中文 `README.md`，英文见 `README.en.md`。

总览也写在 [README.zh.md](../README.zh.md) 的「GitHub 附加与可选」与「kit 之外怎么长」。

## 目录

| 插件 | 版本 | 一句话 |
|------|------|--------|
| [dsh-wsl-llamacpp](https://github.com/173787247/dsh-wsl-llamacpp) | 0.1.0 | 对接本机 llama.cpp / Unsloth Desktop 的 OpenAI 兼容接口（默认 :8080）。 |
| [dsh-wsl-vllm](https://github.com/173787247/dsh-wsl-vllm) | 0.1.0 | 对接本机/Docker vLLM 的 OpenAI 兼容服务（默认 :8000）。 |
| [dsh-wsl-struct](https://github.com/173787247/dsh-wsl-struct) | 0.1.0 | 沙箱化 jq / yq / sqlite3（只读 SELECT）。 |
| [dsh-wsl-git](https://github.com/173787247/dsh-wsl-git) | 0.1.0 | 截断版 git status / diff --stat，避免巨型 diff 灌上下文。 |
| [dsh-wsl-tmux](https://github.com/173787247/dsh-wsl-tmux) | 0.1.0 | 只读查看 tmux 会话与 pane 输出。 |
| [dsh-wsl-compose](https://github.com/173787247/dsh-wsl-compose) | 0.1.0 | docker compose：ps/logs；up/down 需双重确认。 |
| [dsh-wsl-systemd](https://github.com/173787247/dsh-wsl-systemd) | 0.1.0 | systemd --user 只读：list / show / journal。 |
| [dsh-wsl-helm](https://github.com/173787247/dsh-wsl-helm) | 0.1.0 | Helm 只读：list / status / history。 |
| [dsh-wsl-terraform](https://github.com/173787247/dsh-wsl-terraform) | 0.1.0 | terraform/tofu：plan 摘要 + state list（永不 apply）。 |
| [dsh-wsl-rclone](https://github.com/173787247/dsh-wsl-rclone) | 0.1.0 | rclone 只读：listremotes / lsf / about。 |
| [dsh-wsl-db](https://github.com/173787247/dsh-wsl-db) | 0.1.0 | psql / redis-cli 只读探针。 |
| [dsh-wsl-glab](https://github.com/173787247/dsh-wsl-glab) | 0.1.0 | GitLab CLI（glab）只读：MR / issue / ci status。 |
| [dsh-wsl-playwright](https://github.com/173787247/dsh-wsl-playwright) | 0.1.0 | WSL 无头 Playwright 抓取页面标题与正文。 |
| [dsh-wsl-mail](https://github.com/173787247/dsh-wsl-mail) | 0.1.0 | 邮件只读：himalaya list / notmuch search。 |
| [dsh-wsl-cal](https://github.com/173787247/dsh-wsl-cal) | 0.1.0 | 日历只读：khal list / today。 |
| [dsh-wsl-pkg](https://github.com/173787247/dsh-wsl-pkg) | 0.1.0 | 依赖树摘要：npm ls / pip list / cargo tree。 |
| [dsh-wsl-media](https://github.com/173787247/dsh-wsl-media) | 0.2.0 | 本地媒体/文档管线：ffprobe、抽音轨、缩略图、PDF、ASR、pandoc、OCR、exif。 |

另见早期可选：`dsh-wsl-ollama` / `search` / `vecmem` / `k8s` / `secret` / `jev` / `obsidian` / `im`（已在主 README 表内）。

## 批量链接到 web profile

```sh
bash scripts/link-linux-plugins.sh
```

默认链接一整组可选仓（可用环境变量 `DSH_LINK_PLUGINS` 覆盖名单）。

## License

与各子仓相同（MIT）。
