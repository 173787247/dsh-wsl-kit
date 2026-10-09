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

两个脚本都从 `DSH_WSL_ROOT` 取检出根；不给的话，审计取 kit 自己的上一级目录。
插件与 kit 不在同一级时就必须给。

```sh
export DSH_WSL_ROOT=<你的检出根>
python3 scripts/audit-readmes.py          # 退出码 1 = 有发现
python3 scripts/fix-plugin-version.py     # 能机械修的那一类
```

审计只认**插件仓** —— 判据是 `package.json` 里有 `dsh` 字段。同一目录下的库
（`dsh-wsl-common`）、独立工具（`dsh-steward`）、草稿目录都不是插件，会被跳过。

---

## 四、这套仓的全貌（写操作前必看）

```
★ 插件仓            70 个（GitHub 上 75 个 dsh*，减去 4 个非插件仓与 1 个库）
★★ 检出位置          <你的检出根>（本机是 /mnt/c/Users/<你>/Desktop/AIFullStackDevelopment）/dsh-*
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

## 2026-10-09 · 集合包（`package.json`）

kit 里加了一个 `package.json`，把同样那 31 个插件描述成一个集合包
（`dsh.bundle.patch` → `cordis.patch.yml`）。

**它现在装不起来**，实测：

```
pnpm add github:173787247/dsh-wsl-kit
  → ERR_PNPM_EXOTIC_SUBDEP: Exotic dependency "dsh-wsl-tray-launcher"
    (resolved via git-repository) is not allowed in subdependencies
    when blockExoticSubdeps is enabled
```

pnpm 禁止 git 解析的依赖出现在另一个 git 解析的包里 ⇒ `github:` 集合包不能依赖 `github:` 插件。
**只有插件上了 npm、依赖变成普通版本范围，这个包才成立。**

⇒ 在那之前 `install.sh` 仍是唯一入口；两个 README 里都写了这一段，别删。

另外两件同一晚确定的事：

- **awesome 明确不收录 kit**（见 `docs/AWESOME_QUEUE.zh.md:6`）。规则第 7 条是"纯聚合包不单独收录"；
  kit 因为 patch 里每条 insert 都带 config（合成配置）落在例外里，但那边已经表过态，不必再试。
- **插件包名与仓名可以不同，但有四处必须一致**：`<repo>/package.json` 的 `name`、
  `<repo>/cordis.patch.yml` 的 `name:`、profile 的 `dependencies` 键、profile 的 `dsh.profile.bundles`。
  漏掉任何一处，表现是"插件静默消失"，不报错。`cordis.patch.yml` 与 profile 里的 `id:` 不要改 ——
  它是配置覆盖的引用点。

### 改名后要同步的地方（实测清单）

包名与仓名可以不同，但**引用包名的地方**必须跟着改。区分靠"它去哪找东西"：

| 去哪找 | 用什么名字 | 例 |
|---|---|---|
| profile 的 `node_modules/<name>` | **包名** | `scripts/check-plugin-versions.sh` 的 `FLOOR` 键与 `TRACKED` 列表 |
| `~/src/<name>`（同级检出） | **仓名** | `scripts/smoke-verticals.sh` 的 `need_dir` 与 `load` |
| `github.com/173787247/<name>` | **仓名** | 所有 README 链接、`docs/awesome-queue/*.yml` |
| `cordis.patch.yml` 的 `id:` | 不改 | 它是配置覆盖的引用点 |
| `cordis.patch.yml` 的 `name:` | **包名** | Cordis 解析 `node_modules` 的键 |

2026-10-09 改过名的三个：`dsh-wsl-tray→dsh-wsl-tray-launcher`、`dsh-wsl-expose→dsh-wsl-portproxy`、
`dsh-wsl-workspace→dsh-wsl-workspace-check`。当时漏了 `check-plugin-versions.sh`，那个检查器
因此报 MISSING 却看不出原因 —— **改完名要跑一次 `scripts/check-plugin-versions.sh`**。
