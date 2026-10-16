# 升级 dsh —— 五层，每层都要能失败地验一遍

> 起因：一次「升级成功」之后界面能开，但功能悄悄少了一批。
> 根因不在 dsh 本体，而在**漏掉的第四层**（profile 里钉的插件版本）。
> 所以这份文档按**层**写，而不是按命令写：每一层都有一个**能红**的判据。

## 五层

```
① dsh 本体          npm 包 @deepseek-ai/dsh
② 本地定制          kit 的 local-patches/（undici · cordis 补丁 · 脚本路径翻译）
③ profile 的插件版本  ~/.dsh/profiles/*/package.json 里 @deepseek-ai/* 的钉版本
④ 会话/存档兼容      旧格式的 session 与配置键
⑤ 保活链            改了 dsh 就要重启，而重启会杀掉发命令的那个会话
```

`scripts/upgrade-dsh-full.sh` 覆盖 ①②③⑤；④ 靠启动日志看。

## 为什么要一次跑完，而不是分几步

升级第 2 步会 `pkill -f 'dsh web'`，**而发命令的这个会话就跑在 dsh 里面**。
不脱离的话链条会在第一步断掉，留下一个没有 dsh 的状态。所以：

```bash
systemd-run --user --collect --unit=dsh-upgrade-$(date +%H%M%S) \
  --property=KillMode=process \
  /bin/bash "$HOME/src/dsh-wsl-kit/scripts/upgrade-dsh-full.sh" \
  https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.1-alpha.4
```

脚本接受 **release URL**（人手上拿到的就是 URL，不是裸版本号）。
`--dry` 只打印计划。

## 每层的判据

| 层 | 判据 | 会红的样子 |
|---|---|---|
| ① | `dsh --version` | 还是旧版本 |
| ② | `bash scripts/apply-local-patches.sh --check` | 某条补丁「打不上」，脚本退出码非 0 |
| ③ | 启动日志里 `grep -c 'disabling profile plugin row'` **不再增加** | 见下 |
| ④ | 会话能 resume；启动日志没有格式/字段报错 | resume 报错 |
| ⑤ | `%USERPROFILE%\dsh-ui-watcher.log` 的最后写入时间 < 3 分钟 | 见下 |

### 第③层的红长什么样（这一层最容易漏）

```
dsh: disabling profile plugin row "agent-team":
     Plugin @deepseek-ai/dsh-experimental-agent-team@0.2.1-alpha.2
     is incompatible with dsh 0.2.1-alpha.4:
     requirements {"@deepseek-ai/dsh-agent":"0.2.1-alpha.2", ...}
```

⇒ dsh 把那一行**整行禁用**。**它不是报错，是安静地没有** —— 所以不看启动日志发现不了。

★ 而且日志是**追加**的 ⇒ `grep -c` 数的是历史累计，**必须看最新一次启动之后有没有新的**。
最省事的判据：重启前记下日志字节数，重启后只看新增那段。

### 第③层怎么修

```bash
dsh plugin --profile web add <包名>@<与本体相同的版本>
```

- **必须用 dsh 自己的安装器**（它走 pnpm）。profile 里有 `link:` / `github:` 依赖，
  普通 `npm install` 会直接 `EUNSUPPORTEDPROTOCOL` 失败。
- 只升**同一条版本轨**的包：本体 `0.2.1-alpha.4` ⇒ 只把 `0.2.1-alpha.N` 升上来，
  `0.1.x` 的插件不碰（它们未必跟本体同版本发布）。

## 三个实测踩过的坑

### 1. 保活件会卡死在一个没有超时的外部命令上

`dsh-ui-watcher.ps1` 靠 `wsl.exe` 读 `/tmp/dsh-ui-url`。原来的写法是

```powershell
$raw = (& wsl.exe -d $distro -- bash -lc "cat $urlFile 2>/dev/null" | Out-String)
```

WSL 停摆时这个调用**永远挂住**，`while($true)` 卡死在这一行，
**连 `catch` 都进不去**（根本没抛异常）⇒ WSL 回来之后它也不会醒。

- 症状：心跳日志**一行错误都没有就停了**，而 token 文件其实在。
- 修法：把调用放进 `Start-Job` + `Wait-Job -Timeout`（见下）。
- 判据：心跳日志里出现 `wsl.exe TIMEOUT ... -> job stopped`，而**之后的 `alive` 继续写**。

★ **不要**改用 `Start-Process -RedirectStandardOutput` 或
`System.Diagnostics.Process` + 重定向：非交互且无控制台时 `wsl.exe` 不输出内容，
而是把一条中文错误写进 stdout（实测 `first16 = 0d 4e 58 5b …`，UTF-16LE）。
**只有 `Start-Job` 这一种既拿得到内容、又超得了时。**

### 2. 两套启动逻辑会抢同一个端口

- systemd 的 `dsh-web.service`（开机自启）跑 `restart-dsh-web.sh`
- 桌面「DSH WSL」快捷方式跑 `start-dsh-web.ps1` → `revive-dsh.sh`（**经 `wsl.exe`**）

两边同时起 ⇒ 其中一个抢到端口，另一个的进程死掉，
而服务那边只剩一个 relay 指着别人的进程 ⇒ **看着是好的，其实没有任何东西在管它**。

判据：`ss -ltnp | grep :3080` 拿到的 pid，它的 cgroup 应该是 `…/dsh-web.service`；
若是 `/init.scope`，那它就是从 Windows 侧起的，systemd 管不到它。

### 3. 日志是追加的，`grep -c` 会骗人

`grep -c 'disabling profile plugin row'` 在升级**成功之后**仍然是 9。
因为那是四次启动的历史累计。

判据要看**位置**：这些行全在文件前 42 行，而文件有 211 行 ⇒ 最新一次启动追加的部分里一条都没有。

## 升完的收尾清单

```bash
dsh --version                                    # ① 目标版本
bash "$HOME/src/dsh-wsl-kit/scripts/apply-local-patches.sh --check"   # ②
grep -c 'disabling profile plugin row' /tmp/dsh-web.log               # ③ 只看新增段
ss -ltnp | grep -E ':3080|:3081'                                      # ⑤ 谁的 cgroup
# ⑤ 心跳：%USERPROFILE%\dsh-ui-watcher.log 的最后写入时间 < 3 分钟
```

### 4. 经 `wsl.exe` 传的 bash 命令里不要放引号

`wsl.exe` 的参数在 PowerShell 侧会被重新拼成命令行，**内嵌的双引号会被吃掉**，
于是 bash 收到一条残缺的命令 —— 而症状是**挂住**，不是报错。

```
同一个 curl：
  带引号  'curl --noproxy "*" -w "%{http_code}" …'   ⇒ TIMEOUT
  无引号  'curl --noproxy 127.0.0.1 -w %{http_code} …' ⇒ 401
```

⇒ 要传引号就用别的方式（写进脚本文件、或用不含引号的等价写法）。

### 5. 保活件有【两份】，改一份不够

同一份 `dsh-ui-watcher.ps1` 存在两处：

```
$KIT/bootstrap/windows/dsh-ui-watcher.ps1     ← 启动文件夹的 .lnk 现在指这里
~/.dsh/tray/dsh-ui-watcher.ps1                ← 更早的副本，历史上曾被 .lnk 指着
```

`.lnk` 的目标**被改过不只一次**（有会话记录到当时活的是 tray 那份）。
⇒ 改保活件时**两份一起改**，否则哪天 `.lnk` 指回另一份，修复就静默失效。

★ 判据（不是看文件，是看在跑的那个）：
```powershell
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*dsh-ui-watcher*' -and
                 $_.CommandLine -notlike '*Get-CimInstance*' } |
  Select-Object ProcessId, CommandLine
```

### 6. `-WindowStyle Hidden` 不等于「没有窗口」—— 那个窗口里就是保活件

Windows 会把 `-WindowStyle Hidden` 起的 PowerShell **托管进一个 Windows Terminal 窗口**
（最小化，标题是 `Windows PowerShell`）。所以桌面上会看到这样一个窗口，
而**关掉它 = 关掉保活件**。

它很难被发现，因为：

```
· 窗口属于 WindowsTerminal 的宿主进程，不是 powershell.exe 的 pid
· 里面的 shell 挂在 OpenConsole.exe 下面，不是 WindowsTerminal 的直接子进程
  ⇒ 用 ParentProcessId=<WT 的 pid> 查子进程会得到「没有子进程」，
    于是误判成「空壳窗口」，放心关掉 —— 保活件就这样被关掉过一次
```

**关任何 `Windows PowerShell` 窗口之前，先跑这个**：

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -like '*dsh-ui-watcher*' -and
                 $_.CommandLine -notlike '*Get-CimInstance*' -and
                 $_.CommandLine -notlike '*-like*' } |
  Select-Object ProcessId, ParentProcessId, CommandLine
```

有输出 ⇒ 那个窗口里是保活件，**不要关**。

★ 想让它彻底不占窗口：改用任务计划程序而不是启动文件夹 ——
  见 `bootstrap/windows/dsh-ui-watcher.ps1` 头部推荐的那条 `schtasks` 命令。
  任务计划程序跑在非交互会话里，不产生窗口。
