# 维护手册

> 这份文档写给接手维护的人。它讲**这个仓里每个东西是干什么的、哪个脚本在什么时候跑、
> 有哪些不变量不能破**。架构本身不在这里 —— 见
> [README.md](../README.md) 的 *How the pieces fit* 与
> [docs/OPTIONAL_PLUGINS.md](./OPTIONAL_PLUGINS.md)。

## 一、仓库地图

| 路径 | 是什么 | 谁在写它 |
|---|---|---|
| `README.md` / `README.zh.md` | 架构、安装集、边界表、完整目录 | **手写**。改架构时改这里 |
| `docs/OPTIONAL_PLUGINS.md` / `.zh.md` | 22 个可选插件的目录表 | **生成** —— `scripts/expand-optional-docs.py` |
| `docs/CALL_CHAINS.zh.md` | 跨插件的推荐调用链 | 手写 |
| `docs/ENHANCEMENT_QUEUE.zh.md` | 加深队列 | 手写 |
| `docs/TROUBLESHOOTING.md` / `.zh.md` | 排障 | 手写 |
| `docs/AWESOME_QUEUE.zh.md` | awesome 提交排期说明 | 手写 |
| `docs/awesome-queue/wave-*/` | 每仓一个 `owner__repo.yml`，共 30 个 | 手写，一个 PR 一个文件 |
| `awesome-wsl-kit.md` | kit 自己的 awesome 条目 | 手写 |
| `install.sh` | 把 Daily / GitHub / LLM / Full 装进 web profile | 手写。**改安装集必须同步改 README 的表** |
| `cordis.patch.yml` | 装进 profile 的 cordis 补丁 | 手写 |
| `examples/` | LLM provider 设置与补丁示例 | 手写 |
| `scripts/` | 32 个维护脚本，见下节 | 手写 |

**双语配对状况**（不齐，是有意的）：

| 有 `.md` + `.zh.md` | 仅中文 | 仅英文 |
|---|---|---|
| `README`、`OPTIONAL_PLUGINS`、`TROUBLESHOOTING` | `CALL_CHAINS.zh.md`、`ENHANCEMENT_QUEUE.zh.md`、`AWESOME_QUEUE.zh.md` | — |

新增中文文档时，**不必**补英文；但 `README` / `OPTIONAL_PLUGINS` / `TROUBLESHOOTING`
这三对的英文页要保持同步，因为它们对外。

## 二、维护脚本

### 分发类 —— 改动要铺到几十个仓

| 脚本 | 做什么 | 何时跑 |
|---|---|---|
| `sync-wsl-common.mjs` | 把 `dsh-wsl-common/lib/` 里的 **`wsl-host.js` 与 `wsl.js` 两个文件**覆盖到各插件的 `lib/`。只覆盖**已经存在**该文件的插件（`existsSync(dest)`），不会给没这文件的插件新增。**没有 dry-run / `--check` 模式，直接写。** | **改了这两个文件之后必跑** |
| `banner-kit-readmes.py` | 给每个插件 README 插统一 banner（幂等） | 新增插件后 |
| `push-readme-banners.py` | 把 banner 改动 commit + push 到各仓 | 上一条之后 |
| `bump-verified-dsh.py` | 在各插件 README 里更新「Latest verified」并补 Compatibility 表 | dsh 版本验证通过后 |
| `expand-optional-docs.py` | 生成各可选插件的 `README.md` / `README.en.md` / `README.zh.md` 与 `OPTIONAL_PLUGINS.md` | 可选插件元数据变了之后 |

**`expand-optional-docs.py` 里的元数据表是唯一真相源** —— 改可选插件的版本、
一句话简介、工具列表，改那里再重跑，不要手改生成的 README。

### 安装类

| 脚本 | 做什么 |
|---|---|
| `install.sh` | 主入口。按 `KIT_SET` 装 Daily / GitHub / LLM / Full |
| `link-linux-plugins.sh` | 把可选 Linux 插件 `link:` 进 web profile。可用 `DSH_LINK_PLUGINS` 覆盖名单 |
| `link-remote-bridges.sh` | 同上，针对 remote-ssh / mac-companion / device-bridge |
| `merge-llm-cordis.sh` | 把 `examples/cordis.llm.patch.yml` 合进 profile（幂等覆盖） |
| `refresh-llm-plugins.sh` | 重装 LLM 相关插件 |
| `install-tray.mjs` | 装 Windows 托盘启动器 |

**`link-*` 脚本产生的就是 `link:` 依赖，指向 Windows 侧的仓检出。**
这不是缺陷，是设计：浏览器在 Windows、agent 在 WSL。见 README 的边界表。

### 检查类

| 脚本 | 做什么 | 退出码 |
|---|---|---|
| `check-plugin-versions.sh` | 装了的版本 vs 兄弟仓检出 vs **脚本内的下限表** | 有 STALE/MISSING 则 1 |
| `check-dsh-health.sh` | 端口、dsh 环境、可选代理连通性 | — |
| `check-dsh-ports.sh` | 3080/3081 监听状况 | — |
| `check-dsh-noproxy.sh` | dsh 自身是否绕过代理 | — |
| `check-ollama-ctx.sh` | Ollama `n_ctx` 与 settings 是否对齐 | — |
| `post-install-check.sh` | 装完自检 | — |
| `audit-local.sh` | 本地审计 | — |
| `list-dsh-wsl-repos.py` | 列出所有 dsh-wsl 仓 | — |

**版本下限表在 `check-plugin-versions.sh` 的 `FLOOR` 关联数组里。**
兄弟仓检出不在时，它就是判定依据。**升版本时要同时改这里。**

### 运行 / 排障类

| 脚本 | 做什么 |
|---|---|
| `restart-dsh-web.sh` | 重启 dsh web。**仅回环**，避免继承 Clash 的 RFC1918 `NO_PROXY` |
| `dsh-port-relay.py` | Windows `*:3081` → WSL `127.0.0.1:3080` 的 TCP/HTTP 中继 |
| `dsh-web-alive.inc.sh` | dsh ≥0.1.2 launch-token 认证的共享函数（被 source，不单独执行） |
| `start-dsh-debug.sh` | 确保 localhost 绕过代理 |
| `start-dsh-lan.sh` | LAN 暴露 |
| `probe-dsh.sh` | 探测 dsh 状态 |
| `upgrade-dsh.sh` | 升级 dsh |
| `run-net-doctor.mjs` / `run-docker-doctor.mjs` / `run-host-reach.mjs` | 调用对应诊断插件 |

### 冒烟类

| 脚本 | 范围 |
|---|---|
| `smoke-verticals.sh` | **离线**。只做 import 与纯函数自检，不碰网络与 Windows |
| `smoke-github-kit.sh` | GitHub 相关那套 |

**`smoke-verticals.sh` 是离线可跑的** —— 在没有 Windows 互操作的环境里也能验证插件没坏。

### 提交类

| 脚本 | 做什么 |
|---|---|
| `submit-awesome-wave.ps1` | 按 wave 提交 awesome 条目（PowerShell） |

## 三、不变量

破了这几条，分散在几十个仓里的东西就会开始漂：

1. **`wsl-host.js` 是复制分发，不是 import。**
   `dsh-wsl-common` 是规范源，各插件各持一份拷贝，26 份副本内容必须相同。
   改源头之后**必须**跑 `sync-wsl-common.mjs`，并且**新插件也要自带一份副本**。

   `sync-wsl-common.mjs` 只同步 `wsl-host.js` 和 `wsl.js` 两个文件，
   `proxy.js` 与 `companion_client.js` **不在**同步范围（后者由
   `dsh-device-bridge` / `dsh-mac-companion` 直接 import）。
   它也没有校验模式，跑完自己核一遍：

   ```sh
   # 除 dsh-wsl-obsidian 外应全部同一个 md5（那份是 link: 到 /mnt/c，带 CRLF）
   md5sum ~/.dsh/profiles/web/node_modules/dsh-wsl-*/lib/wsl-host.js | awk '{print $1}' | sort | uniq -c
   ```

2. **可选插件不进 `install.sh`。**
   `OPTIONAL_PLUGINS.md` 开头就写着「These are **not** in `install.sh` / Daily」。
   加进安装集会改变所有 Daily 用户的启动时间与权限面。

3. **`dsh-wsl-common` 与 `dsh-wsl-kit` 不是插件。**
   前者无 `dsh` 字段（是库），后者连 `package.json` 都没有（是脚本与文档）。
   **不要**给它们加 `dsh.bundle`，也**不要**照可选插件的路子去 `link:` 它们。

4. **`link:` 与 `github:` 是两种安装，各有用途。**
   `github:` 用于 `install.sh` 的套装插件；`link:` 用于 `link-*` 脚本装的可选插件，
   指向 Windows 侧检出。**不要为了「统一」把 `link:` 改成 `github:`** ——
   那样就失去了改完即生效的能力。

5. **生成的文档不要手改。**
   `OPTIONAL_PLUGINS.md` 与各可选插件的 `README.md` / `README.en.md` / `README.zh.md`
   由 `expand-optional-docs.py` 产出。要改内容改脚本里的元数据表。

## 四、接手检查清单

在新机器上或怀疑环境漂了时，按顺序：

```sh
bash scripts/check-dsh-ports.sh        # 3080/3081 在听吗
bash scripts/check-dsh-health.sh       # 环境与代理
bash scripts/check-plugin-versions.sh  # 版本对不对（退出码 1 = 有漂）
bash scripts/smoke-verticals.sh        # 插件本体没坏（离线，不碰网络与 Windows）
```

前三条里任何一条失败，先修它再看别的。第四条是离线的，在没有 Windows 互操作时也能跑。

`sync-wsl-common.mjs` **不在**这个清单里 —— 它是写操作，会直接覆盖各插件副本，
不是检查。要核对副本一致性用上面那条 `md5sum`。



## 五、改东西时的连带影响

| 改了 | 必须同步 |
|---|---|
| `install.sh` 的套装组成 | README / README.zh.md 的 Install sets 表 |
| `dsh-wsl-common/lib/wsl-host.js` 或 `wsl.js` | 跑 `sync-wsl-common.mjs`，然后各仓 commit |
| 可选插件的版本或工具列表 | `expand-optional-docs.py` 的元数据表，重跑 |
| 插件版本下限 | `check-plugin-versions.sh` 的 `FLOOR` 表 |
| 装进 profile 的 cordis 补丁 | `cordis.patch.yml` 与 `examples/` 两处 |
| 新增一个插件仓 | `banner-kit-readmes.py` → `push-readme-banners.py`，README 目录加一行，awesome queue 排 wave |
