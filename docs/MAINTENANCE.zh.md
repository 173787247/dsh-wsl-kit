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
| **加一条新的本地定制** | `local-patches/` 放幂等脚本 + `apply-local-patches.sh` 的 `PATCHES` 加一行 + 6.6 的表加一行 |
| 新增一个插件仓 | `banner-kit-readmes.py` → `push-readme-banners.py`，README 目录加一行，awesome queue 排 wave |

---

## 六、升级 dsh

### 6.1 为什么不能直接 `npm install -g`

```sh
npm install -g --prefix ~/.local @deepseek-ai/dsh@<版本>
```

这一条会**覆盖整个 `node_modules`**。而我们对 dsh 做过的改动就在那里面 ——
升完就没了。**「每次升级都重头再来」不是进化，是原地打转。**

### 6.2 升级会冲掉什么、不会冲掉什么

| 东西 | 会不会被冲 | 在哪 |
|---|---|---|
| **undici 7.18.2 替换**（Cursor 修的 `web_search`） | ★ **会** | `node_modules/undici` |
| **三个 cordis 补丁**（我打的） | ★ **会** | `node_modules/@deepseek-ai/cordis*` |
| `cordis.patch.yml`（Cursor 改的，8558 B） | ✓ 不会 | `~/.dsh/profiles/web/` |
| `~/.dsh/settings.yaml` | ✓ 不会 | 同上 |
| 22 个 `link:` 插件 | ✓ 不会 | 指向 Windows 侧检出 |
| 本仓的 32 个脚本与文档 | ✓ 不会 | 不在 `node_modules` |

**★ 所以升级要重打的只有两项 —— 而它们已经做成幂等脚本。**

### 6.3 一条命令升级

```sh
systemd-run --user --collect --unit=dsh-upgrade-$(date +%H%M%S) \
  --property=KillMode=process \
  /bin/bash ~/src/dsh-wsl-kit/scripts/upgrade-dsh-full.sh 0.2.0-rc.1
```

**★ 为什么必须 `systemd-run` 而不是直接跑**：升级会 `pkill dsh web`，
而你的 shell 是 `dsh web` 的子进程（`bash ← dsh web ← Relay ← systemd`）——
直接跑会在装到一半时把自己杀掉。`KillMode=process` 也是必须的，否则 unit
拆除时会把刚起来的 dsh web 一起 SIGKILL（**这正是当初「起来 30 秒又没了」的机制，
由 Cursor 诊断出来**）。

**先干跑看清要做什么：**

```sh
bash ~/src/dsh-wsl-kit/scripts/upgrade-dsh-full.sh --dry 0.2.0-rc.1
```

脚本做六步：**备份 → 停 → 装 → 重打本地定制 → 起回来 → 总结**，
装失败自动回滚。

### 6.4 验证升级成功

```sh
dsh --version                                          # ① 版本号变了
pgrep -f 'dsh web --no-open --port 3080'               # ② 起来了
cat /tmp/dsh-upgrade.log                               # ③ 日志走到第 6/6
bash ~/src/dsh-wsl-kit/scripts/apply-local-patches.sh --check   # ④ 定制都在
```

**④ 是这次升级特有的** —— 官方升级不是"装完就完"，还要确认定制都回来了。

### 6.5 回滚

```sh
BK=$(cat /tmp/dsh-upgrade-backup-path)
rm -rf ~/.local/lib/node_modules/@deepseek-ai/dsh
cp -r "$BK/dsh-before" ~/.local/lib/node_modules/@deepseek-ai/dsh
bash ~/src/dsh-wsl-kit/scripts/restart-dsh-web-detached.sh
```

备份在 `~/.dsh/dsh-upgrade-backup-<时间戳>/`，含 dsh 整包、`cordis.patch.yml`、
`backport/*.patch`、升级前版本号。

### 6.6 本地定制清单

**唯一真相源：`local-patches/`（同目录 `README.zh.md` 有完整说明）**

| # | 脚本 | 改什么 | 为什么 |
|---|---|---|---|
| 01 | `01-undici-7.18.2.sh` | dsh 内嵌 undici `8.11.0` → `7.18.2` | Node 24 内置 fetch 来自 undici 7.x；跨大版本的 ProxyAgent 作全局 dispatcher 会**丢响应头** → `content-encoding` 丢失 → brotli 不解压 → `web_search` 的 JSON.parse 失败。**Cursor 于 2026-09-26 诊断并修复**，记录在 `~/GO/dsh-websearch-修复记录.md` |
| 02 | `02-cordis-backports.sh` | 三个 cordis 补丁 | 线上 cordis 的真实缺陷：插件在 `update` 时抛异常 → 逃逸成 unhandled rejection → **进程被打死**。打补丁前 15 agreed + i5 崩溃；打补丁后 19 agreed，零回归（2026-09-28 差分验证） |

**加一条新定制**：在 `scripts/apply-local-patches.sh` 的 `PATCHES` 数组加一行，
并在 `local-patches/` 放一个幂等脚本。验证器会自动带上它。

### 6.7 ★ 演练过，不是"应该能用"

2026-09-29 在 `/tmp/dsh-rehearsal/` 里做过一次**隔离演练**，全程没碰线上：

```
① 复制 dsh 到隔离目录
② 模拟「官方升级」—— undici 换回 8.11.0，三个 cordis 补丁反向还原
   → 得到 43e7e5c5 / 3e2e273b / c651cbea，与线上官方原版【逐字节相同】
③ --check           ★ 正确报「未生效」，退出码 1
④ apply-local-patches.sh   ✓ 3 个补丁重打 + undici 换成 7.18.2
⑤ 再验证            ✓ 两项全通过，退出码 0
```

**★ 第 ③ 步是反向验证**：如果检查器对未打补丁的环境也说"通过"，那它就是个假检查。
它报了失败，所以它是真的。

---

## 七、重启之后，浏览器怎么自己回来

### 7.1 那一环为什么难

```
agent 跑在 dsh web 里
  → 重启 dsh web = 杀掉自己
  → 重启后要回来，需要浏览器打开【新的】 token URL（token 每进程一变）
  → ★ 而"开浏览器"这件事，从 WSL 里做不成
```

**★★ 从 systemd 单元里调 `powershell.exe Start-Process`：退出码 0，浏览器不出现。**

那是非交互式会话，到不了用户的桌面 —— 而它还返回 0，把调用者骗过去，
于是脚本报「已打开」，人却还得点桌面。

### 7.2 正确的分工

```
WSL 侧     负责重启
Windows 侧 负责开浏览器
```

桌面快捷方式一直是这么做的（`start-dsh-web.ps1`：先 `wsl.exe ... restart`，
再 `Start-Process $url`），所以它一直能成。

### 7.3 常驻者：`~/.dsh/tray/dsh-ui-watcher.ps1`

让 WSL 侧也能"自己回来"的，是 Windows 上的一个常驻进程：

```powershell
每 2 秒读 WSL 里的 /tmp/dsh-ui-url
  内容变了（= dsh 重启了）→ Set-Clipboard + Start-Process
```

**安装**（Startup 文件夹，不需要管理员；`Register-ScheduledTask` 需要管理员，会失败）：

```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\DSH UI Watcher.lnk
  → powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden
       -File \\wsl.localhost\<发行版>\home\<用户>\.dsh\tray\dsh-ui-watcher.ps1
```

**查它活着**（★ 注意排除查询命令自身，否则会数到自己）：

```powershell
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*dsh-ui-watcher.ps1*' -and
                 $_.CommandLine -notlike '*Get-CimInstance*' -and
                 $_.CommandLine -notlike '*-like*' }
```

**看它的日志**（v2 起有日志，v1 死过一次没留任何线索）：

```
%USERPROFILE%\dsh-ui-watcher.log
```

每分钟一行 `alive; last=…` 是心跳。**没有心跳就是死了。**

### 7.4 首次成功（2026-09-29 19:48）

```
19:48:41  alive; last=http://127.0.0.1:3081/?token=<token>
19:48:50  restart detected -> http://127.0.0.1:3081/?token=<token>
19:48:50  opened ok
```

★ **`<token>` 是每次启动新签的一次性令牌，不是固定值** —— 所以这里不必也不能写死一个。

会话没有断，人没有点桌面。**闭环第一次跑通。**

### 7.5 注意

- **v1 的教训**：它死过一次，而且没写日志，所以查不出原因。**所以常驻者必须写日志。**
- `upgrade-dsh-full.sh` 里发起 `systemd-run` 时**要显式把 Windows 路径加进 `PATH`**，
  否则 `command -v powershell.exe` 找不到，那一整步静默跳过。
- **桌面快捷方式仍然是保底**，而且它从未被改动过 —— 无论 watcher 在不在，点它就是能进。

---

## 八、套件级的版本适配（每有新 dsh 就做一次）

**用户已把这件事长期交给维护者，不必每次问。** 触发条件：dsh 发了新版本（含 pre-release）。

### 8.1 顺序

```sh
# 1 全部检出做 import 自检（离线，不碰网络与 Windows）
W=<你的检出根>（本机是 /mnt/c/Users/<你>/Desktop/AIFullStackDevelopment）
node /tmp/import-smoke.mjs "$W"        # 全部仓的 lib/*.js 能不能加载

# 2 离线冒烟（覆盖核心的十个）
DSH_WSL_ROOT="$W" bash scripts/smoke-verticals.sh

# 3 版本检查（装了的 vs 兄弟仓 vs FLOOR 表）
bash scripts/check-plugin-versions.sh

# 4 ★ 先预演再改 —— 142 个文件，不能盲改
DSH_BUMP_ROOT="$W" DSH_BUMP_DRY=1 python3 scripts/bump-verified-dsh.py

# 5 正式改
DSH_BUMP_ROOT="$W" python3 scripts/bump-verified-dsh.py

# 6 提交推送 —— ★ 只 add README*.md
for d in "$W"/dsh-*; do
  git -C "$d" diff --quiet -- 'README*.md' || {
    git -C "$d" add -- 'README*.md'
    # ★ 用你自己的提交身份；没配全局 git 身份时才需要 -c
    git -C "$d" commit -q -m "docs: verified against dsh <版本>"
    git -C "$d" -c http.proxy=$HTTP_PROXY push -q origin HEAD
  }
done
```

### 8.2 四个坑（都踩过）

| 坑 | 症状 | 处理 |
|---|---|---|
| **CRLF 假象** | `/mnt/c` 下几百个文件显示 "已修改" | ★ 判据不是 `--ignore-all-space`（它不忽略 `\r`），而是**把两端都 `tr -d '\r'` 后比 md5**。归一后相同 = 假象 |
| **只 add README** | 否则会把几百个 CRLF 文件一起提交 | `git add -- 'README*.md'`，逐仓提交 |
| **SSH 不通** | `git@github.com: Permission denied (publickey)` | 全套仓的 origin 都是 **HTTPS**，用 HTTPS；`git -c http.proxy=$HTTP_PROXY` |
| **两份 kit** | `~/src` 与 `/mnt/c` 曾同名，HEAD 不同 | `~/src` 是主力。`/mnt/c` 那份**已改名 `dsh-wsl-kit.mirror`**（2026-09-29），不再同名；它是镜像，`git pull` 即同步。**改之前先确认改的是哪一份** |

### 8.3 为什么要先自检再改 README

**因为"适配"的结论可能是"不需要改代码"。** 2026-09-29 那次（→ `0.2.0-rc.2`）就是：
71 个检出 import 全通过、冒烟全绿、地板版本未变 —— 于是只动了文档声明。
**先跑测试，才知道该改什么。**

### 8.4 别忘的收尾

- kit 自己的 `README.md` / `README.zh.md` 的兼容性表 —— `bump` 脚本 **SKIP** 它，要手改两处
- `scripts/check-plugin-versions.sh` 的 `FLOOR` 表（若下限变了）
- `install.sh` 的套装组成若有变，同步改 README 的表


---

## 九、commit message 与对外文档的写法

**说结果，不说过程。**

```
✓ 改了什么、为什么应该这样
✗ 怎么发现的、先试了什么、花了多久、中间哪里绕了弯、上一个助手是谁
```

**判据**：一段话如果去掉「我当时怎么想/怎么试」也照样成立，那它就是对的段落；
如果它只有讲了曲折才读得通，那它就该留在这段对话里，而不是留在历史里。

**同样适用于任何推出去的东西** —— 文档描述的是那件东西，不是抵达它的过程。

**放哪里**：
- 过程 → 这段对话，或仓里的交接文件（`START-HERE.md` / `docs/HANDOFF-*.md`）
- 结果 → commit message、README、`docs/`
