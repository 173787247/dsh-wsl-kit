# Cursor 时代的建仓脚本（归档）

**这些不做维护，也不该再跑。** 收在这里只为了留个物证。

## 是什么

2026-09 用 Cursor 批量新建五个插件仓（`ollama` / `media` / `search` / `vecmem` / `k8s`）时用的一次性工具：

| 脚本 | 当时做什么 |
|---|---|
| `push-new-linux-plugins.sh` / `.ps1` | `gh repo create` 建仓 + 首次推送 + 打 topic |
| `pad-and-push-secret.ps1` | ★ 给新仓**凑提交数**，以过 awesome 的门槛（它自己的注释：「submit after repo age >=1 day and 10+ commits」）；顺带生成 `awesome-entry.yml` 与 `examples/plugin.env.example` |
| `finish-link-secret.sh` | 把 `dsh-wsl-secret` link 进 profile |
| `grep-new-plugins-log.sh` | 从 `/tmp/dsh-web.log` 里看那几个插件的加载情况 |

## 为什么不继续用

1. **硬编码一次性参数** —— 五个插件名、`~/.cursor/git-hooks`、绝对路径。
2. **★ 那个"凑提交数"的目标本身不该继续** —— 为满足门槛制造提交，是把门槛当形式。
   真要有提交，就做真的事。

## 那份旧副本

这些脚本原在 `/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-wsl-kit/` ——
那是 Cursor 时代的工作副本，已落后于 `~/src/dsh-wsl-kit`（主力）。
它曾在三个主力脚本里被硬编码引用，已于 2026-09-29 改成自定位。
