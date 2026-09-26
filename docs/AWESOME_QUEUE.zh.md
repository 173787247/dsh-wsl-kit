# awesome-dsh-plugin 收录队列

对照：[awesome-dsh-plugin/awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)  
门槛：**仓龄 ≥ 1 天**；每 PR **最多 3** 条。

不收录：`dsh-wsl-kit`、`dsh-wsl-common`。YAML：[`awesome-queue/`](./awesome-queue/)。

更新于 **2026-09-25 17:40（UTC+8）**。

## 状态

| Wave | 插件 | 状态 |
|------|------|------|
| **A** | jev · obsidian | **已在 main** |
| **B** | secret · ollama · media | **已合入** [#5783](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5783) |
| **C** | search · vecmem · k8s | **已合入** [#5784](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5784) |
| **D** | llamacpp · vllm · struct | **已合入** [#5785](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5785) |
| **E** | git · tmux · compose | **已合入** [#5786](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5786) |
| **F** | systemd · helm · terraform | **已合入** [#5787](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5787) |
| **G** | rclone · db · glab | **已合入** [#5788](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5788) |
| **H** | playwright · mail · cal | **已合入** [#5789](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5789) |
| **I** | pkg | **已合入** [#5790](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5790) |
| **J** | remote-ssh · mac-companion · device-bridge | **已合入** [#5873](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5873) |

A–J 全部合入。远程桥接三仓已在 awesome；本机可 `bash scripts/link-remote-bridges.sh` + ssh-lab 冒烟。

## 加深后描述更新（2026-09-26）

| PR | 内容 | 状态 |
|----|------|------|
| [#5926](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5926) | `dsh-wsl-im`（Mattermost / ASR / 白名单） | open |
| [#5927](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5927) | remote-ssh · mac-companion · device-bridge | open |
| [#5928](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5928) | editor · notify · picker | open |

## Wave J 说明

| 仓 | 创建（UTC） | PR |
|----|-------------|-----|
| [dsh-remote-ssh](https://github.com/173787247/dsh-remote-ssh) | 2026-09-24 06:07 | [#5873](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5873) **merged** |
| [dsh-mac-companion](https://github.com/173787247/dsh-mac-companion) | 2026-09-24 06:08 | 同上 |
| [dsh-device-bridge](https://github.com/173787247/dsh-device-bridge) | 2026-09-24 06:08 | 同上 |

分类均用 `wsl`（与既有 WSL 套件条目一致；插件本身不要求装在每台远端机上）。
