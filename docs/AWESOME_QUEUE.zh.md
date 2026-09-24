# awesome-dsh-plugin 收录队列

对照：[awesome-dsh-plugin/awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)  
门槛：**仓龄 ≥ 1 天**；每 PR **最多 3** 条。

不收录：`dsh-wsl-kit`、`dsh-wsl-common`。YAML：[`awesome-queue/`](./awesome-queue/)。

更新于 **2026-09-24 14:30（UTC+8）**。

## 状态

| Wave | 插件 | 状态 |
|------|------|------|
| **A** | jev · obsidian | **已在 main** |
| **B** | secret · ollama · media | [#5783](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5783) OPEN · CI 绿 |
| **C** | search · vecmem · k8s | [#5784](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5784) OPEN · CI 绿 |
| **D** | llamacpp · vllm · struct | [#5785](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5785) OPEN · CI 绿 |
| **E** | git · tmux · compose | [#5786](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5786) OPEN · CI 绿（已修大小写） |
| **F** | systemd · helm · terraform | [#5787](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5787) OPEN · CI 绿（已修大小写） |
| **G** | rclone · db · glab | [#5788](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5788) OPEN · CI 绿 |
| **H** | playwright · mail · cal | [#5789](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5789) OPEN · CI 绿 |
| **I** | pkg | [#5790](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5790) OPEN · CI 绿 |
| **J** | remote-ssh · mac-companion · device-bridge | **待提** · YAML 已备 · 最早 **2026-09-25 14:10（UTC+8）** |

提交侧：B–I **24** 条已提等合入；**Wave J**（远程桥接 3 仓）排期明日仓龄满后再开 PR。

## Wave J 说明

| 仓 | 创建（UTC） | 建议提 PR |
|----|-------------|-----------|
| [dsh-remote-ssh](https://github.com/173787247/dsh-remote-ssh) | 2026-09-24 06:07 | ≥ 2026-09-25 14:10 CST |
| [dsh-mac-companion](https://github.com/173787247/dsh-mac-companion) | 2026-09-24 06:08 | 同上 |
| [dsh-device-bridge](https://github.com/173787247/dsh-device-bridge) | 2026-09-24 06:08 | 同上 |

草稿：[`awesome-queue/wave-J/`](./awesome-queue/wave-J/)。到期执行：

```powershell
.\scripts\submit-awesome-wave.ps1 J
```

分类均用 `wsl`（与既有 WSL 套件条目一致；插件本身不要求装在每台远端机上）。
