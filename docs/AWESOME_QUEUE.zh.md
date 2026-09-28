# awesome-dsh-plugin 收录队列

对照：[awesome-dsh-plugin/awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)  
门槛：**仓龄 ≥ 1 天**；每 PR **最多 3** 条。

不收录：`dsh-wsl-kit`、`dsh-wsl-common`。YAML：[`awesome-queue/`](./awesome-queue/)。

更新于 **2026-09-28**。

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
| **K** | perf · service · eventlog | **已提交** [#6044](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/6044) |
| **L** | registry · defender · power | **已提交** [#6045](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/6045) |
| **M** | uia · winshot · winctl | **已提交** [#6046](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/6046) |
| **N** | wininput | **已提交** [#6047](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/6047) |

A–J 全部合入。远程桥接三仓已在 awesome；本机可 `bash scripts/link-remote-bridges.sh` + ssh-lab 冒烟。

## Wave K–N：Windows 宿主与桌面（2026-09-27 新建）

十个仓建于 **2026-09-27**，所以首个可提交日是 **2026-09-28**。按每 PR 最多 3 条分四批。

| 仓 | 分类 | 一句话 |
|----|------|--------|
| [dsh-wsl-perf](https://github.com/173787247/dsh-wsl-perf) | `wsl` | 宿主性能计数与占用最高的进程 |
| [dsh-wsl-service](https://github.com/173787247/dsh-wsl-service) | `wsl` | 服务列表；单查时可到依赖、账户、进程号 |
| [dsh-wsl-eventlog](https://github.com/173787247/dsh-wsl-eventlog) | `wsl` | 事件日志，可按来源与时间窗过滤 |
| [dsh-wsl-registry](https://github.com/173787247/dsh-wsl-registry) | `wsl` | 注册表只读，限定在允许的键前缀内 |
| [dsh-wsl-defender](https://github.com/173787247/dsh-wsl-defender) | `wsl` | Defender 状态、近期检出、排除项 |
| [dsh-wsl-power](https://github.com/173787247/dsh-wsl-power) | `wsl` | 电源方案、电池、休眠超时 |
| [dsh-wsl-uia](https://github.com/173787247/dsh-wsl-uia) | `wsl` | UI Automation：窗口枚举、元素树、按名等待 |
| [dsh-wsl-winshot](https://github.com/173787247/dsh-wsl-winshot) | `wsl` | 截窗，可裁剪到区域或指定元素 |
| [dsh-wsl-winctl](https://github.com/173787247/dsh-wsl-winctl) | `wsl` | 窗口控制：激活、最小化、移动、置顶、关闭 |
| [dsh-wsl-wininput](https://github.com/173787247/dsh-wsl-wininput) | `wsl` | 定向输入：按键、点击、滚轮 |

**描述都对着代码写过一遍** —— 收录方会核对描述与实现是否相符，
「Overstating is the one thing that gets an otherwise-good plugin sent back」。
新增的动作（`wait`、`path`、`key`、`scroll`、`state`、`topmost`、裁剪、
`detail`、`subkeys`、provider 过滤、`all`）都写进了对应的描述里。

### K–N 首次提交实录（2026-09-28）

四个 PR 当天全部开出。首轮 CI 的结果值得记下来，因为**收到方的报错提示把人带偏了**：

```
check            FAILURE
Submission gate  FAILURE
  → data/plugins/...perf.yml — bad indentation of a mapping entry (5:40)
  → A common cause is an encoding round-trip: a `zh:` description written in
    UTF-8, opened by an editor as GBK and saved back, comes out as mojibake.
```

**按那段提示去查编码，是白费力气。** 实测把 fork 分支上的文件和本地做字节比对：

```
perf      本地 0f37c6f8  远端 0f37c6f8  ✓ 完全一致
service   本地 736f2d61  远端 736f2d61  ✓ 完全一致
```

**真因是普通 YAML：** 未加引号的标量里不能出现冒号+空格，否则解析成嵌套映射。
7 个条目都用了「X from WSL: 细节」这个句式，冒号正好落在 CI 报的那一列：

```yaml
en: Windows host performance from WSL: CPU, memory, disk and top processes.
                                     ↑ 第 40 列
```

通过的 3 个（eventlog / registry / winshot）值里没有冒号。

**修法：给 `en` / `zh` 的值加引号**，并用收录方同一个 `js-yaml` 在本地复验
—— 解析不过的修复，现在在本地就拦住，不会走到 PR 里。10/10 通过。

**修完之后的 gate：**

```
- repository is 0.7 days old (needs 1) — nothing to do: this check re-runs by
  itself and should clear in about 8h. No need to resubmit, push, or close and
  reopen; the age bar is the only thing failing here.
```

年龄是**唯一一个靠时间自愈**的失败项：`regate.yml` 每 6 小时（UTC 19 分）重跑一次，
匹配 `/days old/` 这条措辞，判定会自己翻绿。**提交了什么都不用做。**

**`dsh-wsl-uia` 与 `dsh-wsl-wininput` 是给 agent 操作桌面的能力**，
收录后在 `install.sh` 里仍属独立的 `KIT_SET=desktop`，不会被 `full` 带进来。

## 加深后描述更新（2026-09-26）

| PR | 内容 | 状态 |
|----|------|------|
| [#5926](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5926) | `dsh-wsl-im`（Mattermost / ASR / 白名单） | open · CI 绿 |
| [#5927](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5927) | remote-ssh · mac-companion · device-bridge | open · CI 绿 |
| [#5928](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5928) | editor · notify · picker | open · CI 绿 |
| [#5956](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5956) | vecmem · search · media | open · CI 绿 |
| [#5964](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5964) | shot · obsidian · ollama | open |
| [#5965](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5965) | k8s · git · compose | open |

## Wave J 说明

| 仓 | 创建（UTC） | PR |
|----|-------------|-----|
| [dsh-remote-ssh](https://github.com/173787247/dsh-remote-ssh) | 2026-09-24 06:07 | [#5873](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5873) **merged** |
| [dsh-mac-companion](https://github.com/173787247/dsh-mac-companion) | 2026-09-24 06:08 | 同上 |
| [dsh-device-bridge](https://github.com/173787247/dsh-device-bridge) | 2026-09-24 06:08 | 同上 |

分类均用 `wsl`（与既有 WSL 套件条目一致；插件本身不要求装在每台远端机上）。
