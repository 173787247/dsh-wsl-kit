# 接手这个仓 —— 从这里开始

> **给新会话的第一页。** 读完再动手。
> 仓：`dsh-wsl-kit` ｜ 主力检出 **`~/src/dsh-wsl-kit`** ｜ 分支 **`master`**
> 当前验证的 dsh：**`0.2.0-rc.2`**

---

## 一、这个仓是什么

**元仓**：文档 + 安装脚本 + 本地定制。**不含插件运行时代码**，**没有 `package.json`**，
**不是插件**（不要给它加 `dsh.bundle`，也不要 `link:` 它）。

它服务一个具体的错配：**浏览器在 Windows，agent 在 WSL。**
每一处跨操作系统的地方，在这个仓里只处理一次。

---

## 二、先读哪几页

| 想知道 | 读 |
|---|---|
| **怎么维护、有哪些不变量、改东西的连带影响** | [`docs/MAINTENANCE.zh.md`](./docs/MAINTENANCE.zh.md) ★ 主文档，九节 |
| dsh 升级怎么做（含四个坑） | MAINTENANCE **第六节** + **第八节** |
| 重启后浏览器怎么自己回来 | MAINTENANCE **第七节** |
| 新机器怎么装 | [`bootstrap/README.zh.md`](./bootstrap/README.zh.md) |
| 排障 | [`docs/TROUBLESHOOTING.zh.md`](./docs/TROUBLESHOOTING.zh.md) |
| 本仓的设计意图 | [`docs/SELF-EVOLUTION.zh.md`](./docs/SELF-EVOLUTION.zh.md) |

---

## 三、日常最容易踩的三件事

### 3.1 ★ 检出在 `/mnt/c`，有几百个文件显示"已修改"

**那是 CRLF，不是改动。** 判据：

```sh
# 两端都去掉 \r 再比 md5 —— 相同就是假象
git show HEAD:FILE | tr -d '\r' | md5sum
tr -d '\r' < FILE | md5sum
```

★ **`--ignore-all-space` 不管用**（它不忽略 `\r`）。提交时永远 `git add -- 'README*.md'`，
别 `git add -A`。

### 3.2 ★ 两份检出

```
~/src/dsh-wsl-kit                    主力，在这里改
/mnt/c/…/AIFullStackDevelopment/
   dsh-wsl-kit.mirror                镜像，git pull 即同步
```

**同名的问题已经解决**（镜像改名了），但改之前仍要确认改的是哪一份。

### 3.3 推之前先看文档有没有漂

```sh
python3 scripts/audit-readmes.py          # 退出码 1 = 有发现
python3 scripts/fix-plugin-version.py     # 能机械修的那一类
```

---

## 四、这套仓的全貌（写操作前必看）

```
★ 插件仓            70 个（GitHub 上 75 个 dsh*，减去 4 个非插件仓与 1 个库）
★★ 检出位置          /mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-*
★★★ origin 全部 HTTPS（不是 SSH —— SSH key 没通）
```

**几个不是插件的：**

| 仓 | 是什么 |
|---|---|
| `dsh-wsl-kit` | 本仓（元仓） |
| `dsh-wsl-common` | 库（无 `dsh` 字段）—— **不该有兼容性表** |
| `dsh-steward` | 监督系统（独立项目） |
| `dsh-cordis-backport` | cordis 补丁与审计（独立项目） |
| `dsh-ga-survey` | 调研材料（内容已归 `~/GO/research/ga-survey/`） |

---

## 五、推出去的东西怎么写

**说结果，不说过程。** 详见 MAINTENANCE **第九节**。

```
✓ 改了什么、为什么应该这样
✗ 怎么发现的、先试了什么、花了多久、哪个助手之前经手
```

**同样适用于 README 和任何对外文档。**

---

## 六、还没做的

| | 是什么 |
|---|---|
| `bootstrap/boot.sh` | 五步已写好，但**没在干净机器上真跑过** |
| MAINTENANCE 第六节 | 升级流程演练过（`/tmp/dsh-rehearsal`），实跑过两次（rc.1 → rc.2） |
| 上游 20 个 PR | 全 open，一个未合 —— 所以 `local-patches/` 仍必需 |
| `dsh-wsl-kit.mirror` | 同步正常，若不再需要可删 |
